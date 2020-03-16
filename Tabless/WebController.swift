import UIKit
import WebKit

protocol WebControllerStateResetDelegate {
    func didRequestResetInWebController(_ webController: WebController)
}

class WebController: NSObject, SearchViewDelegate, StateResettable {

    let view = UIView()

    var webContainerView: WebContainerView!

    var opacityView = UIView()
    var openInSafariLabel = UILabel()
    var openInSafariView = UIView()

    var webContainerViewLeadingConstraint: NSLayoutConstraint?

    var delegate: WebControllerStateResetDelegate?

    // makes it clear loading has started before UIWebView reports back
    private static var initialProgress = 0.04

    private let maxPauseInterval: TimeInterval = 20
    private var pauseTime: Date?

    private var webViewProgressObservationToken: NSKeyValueObservation?

    private let stateClearer: StateClearer

    init(stateClearer: StateClearer) {
        self.stateClearer = stateClearer

        super.init()

        stateClearer.addStateClearRequest(for: self,
                                          after: maxPauseInterval)
        setUpView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadQuery(_ query: String) {
        guard let url = URLBuilder.createURL(query) else {
            return
        }
        webContainerView.searchView.text = query

        webContainerView.setNeedsLayout()
        webContainerView.layoutIfNeeded()

        webContainerView.webView.load(URLRequest(url: url))
    }

    private func setUpView() {
        view.backgroundColor = .clear

        view.addSubview(opacityView)
        opacityView.backgroundColor = .black
        opacityView.translatesAutoresizingMaskIntoConstraints = false
        opacityView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        opacityView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        opacityView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        opacityView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        opacityView.alpha = 0.3

        self.webContainerView = WebContainerView()
        webContainerView.translatesAutoresizingMaskIntoConstraints = false
        webContainerView.preservesSuperviewLayoutMargins = true
        let backSwipeGestureRecognizer =
            UIScreenEdgePanGestureRecognizer(target: self,
                                             action: #selector(handleBackSwipe))
        backSwipeGestureRecognizer.edges = .left
        webContainerView.addGestureRecognizer(backSwipeGestureRecognizer)
        let forwardSwipeGestureRecognizer =
            UIScreenEdgePanGestureRecognizer(target: self,
                                             action: #selector(handleForwardSwipe))
        forwardSwipeGestureRecognizer.edges = .right
        webContainerView.addGestureRecognizer(forwardSwipeGestureRecognizer)
        webContainerView.webView.navigationDelegate = self
        webContainerView.webView.uiDelegate = self
        webContainerView.searchView.searchDelegate = self
        view.addSubview(webContainerView)

        let webContainerViewLeadingConstraint = webContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        webContainerViewLeadingConstraint.isActive = true
        self.webContainerViewLeadingConstraint = webContainerViewLeadingConstraint
        webContainerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        webContainerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        view.addSubview(openInSafariView)
        openInSafariView.layer.masksToBounds = true
        openInSafariView.backgroundColor = UIColor(red: 30/255.0, green: 152/255.0, blue: 247/255.0, alpha: 1.0) // TODO: make this grey
        openInSafariView.translatesAutoresizingMaskIntoConstraints = false
        openInSafariView.leadingAnchor.constraint(equalTo: webContainerView.trailingAnchor).isActive = true
        openInSafariView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        openInSafariView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        openInSafariView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        openInSafariView.addSubview(openInSafariLabel)
        openInSafariLabel.text = "Open in Safari"
        openInSafariLabel.textAlignment = .center
        openInSafariLabel.textColor = .white
        openInSafariLabel.numberOfLines = 2
        openInSafariLabel.translatesAutoresizingMaskIntoConstraints = false
        openInSafariLabel.centerXAnchor.constraint(equalTo: openInSafariView.centerXAnchor).isActive = true
        openInSafariLabel.centerYAnchor.constraint(equalTo: openInSafariView.centerYAnchor).isActive = true
        openInSafariLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        openInSafariLabel.alpha = 0

        setUpLoadingKVO()
    }

    // MARK: KVO

    private func setUpLoadingKVO() {
        webViewProgressObservationToken = webContainerView.webView.observe(\.estimatedProgress,
                                                                           options: [.new])
        { [weak self] _, change in
            if let newValue = change.newValue {
                self?.webContainerView.progressView.setProgress(
                    WebController.initialProgress + newValue * (1 - WebController.initialProgress)
                )
            }
        }
    }

    private func removeLoadingKVO() {
        webViewProgressObservationToken = nil
    }

    // MARK: SearchViewDelegate

    func searchChanged(_ text: String) {
        // No-op
    }

    func searchSubmitted(_ text: String) {
        loadQuery(text)
    }

    func searchCleared() {
        reset()
    }

    // MARK: StateResettable

    func reset() {
        clearWebViewData {
            print("Data cleared")
            // TODO: Handle asynchronicity of this?
        }
        delegate?.didRequestResetInWebController(self)
    }

    private func clearWebViewData(completion: @escaping () -> Void) {
        let aLongTimeAgo = Date(timeIntervalSinceReferenceDate: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                                modifiedSince: aLongTimeAgo) {
                                                    completion()
        }
    }
}

extension WebController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Prevent universal links from opening in apps -- Tabless is meant to
        // be a quick-in, quick-out, historyless experience. Having a video or
        // shopping app that preserves history open when a link is tapped doesn't
        // feel good.
        let disableUniversalLinkingPolicy =
            WKNavigationActionPolicy(rawValue: WKNavigationActionPolicy.allow.rawValue + 2)!
        decisionHandler(disableUniversalLinkingPolicy)
    }
}

extension WebController: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
