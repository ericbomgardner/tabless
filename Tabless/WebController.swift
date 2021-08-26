import UIKit
import WebKit

protocol WebControllerStateResetDelegate {
    func didRequestResetInWebController(_ webController: WebController)
}

class WebController: NSObject, SearchViewDelegate, StateResettable {

    let view = UIView()

    var webContainerView: WebContainerView!

    var opacityView = UIView()

    var webContainerViewLeadingConstraint: NSLayoutConstraint?

    var delegate: WebControllerStateResetDelegate?

    // makes it clear loading has started before UIWebView reports back
    private static var initialProgress = 0.04

    private var pauseTime: Date?

    private var disposeBag = [NSKeyValueObservation]()

    private let stateClearer: StateClearer

    init(stateClearer: StateClearer) {
        self.stateClearer = stateClearer

        super.init()

        stateClearer.addStateClearRequest(for: self)
        setUpView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadQuery(_ query: String) {
        let urlBuilder = URLBuilder(searchEngine: UserDefaults.standard.preferredSearchEngine)
        guard let url = urlBuilder.createURL(query) else {
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
        webContainerView.webView.navigationDelegate = self
        webContainerView.webView.uiDelegate = self
        webContainerView.searchView.searchDelegate = self
        webContainerView.bottomToolbar.backButton.isEnabled = false
        webContainerView.bottomToolbar.forwardButton.isEnabled = false
        webContainerView.bottomToolbar.backButton.addTarget(self,
                                                            action: #selector(didTapBackButtonZZZ),
                                                            for: .touchUpInside)
        webContainerView.bottomToolbar.forwardButton.addTarget(self,
                                                               action: #selector(didTapForwardButton),
                                                               for: .touchUpInside)
        view.addSubview(webContainerView)

        let webContainerViewLeadingConstraint = webContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        webContainerViewLeadingConstraint.isActive = true
        self.webContainerViewLeadingConstraint = webContainerViewLeadingConstraint
        webContainerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        webContainerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        setUpLoadingKVO()
    }

    // MARK: KVO

    private func setUpLoadingKVO() {
        disposeBag.append(webContainerView.webView.observe(\.estimatedProgress,
                                                            options: [.new])
        { [weak self] _, change in
            if let newValue = change.newValue {
                self?.webContainerView.progressView.setProgress(
                    WebController.initialProgress + newValue * (1 - WebController.initialProgress)
                )
            }
        })

        disposeBag.append(webContainerView.webView.observe(\.canGoBack,
                                                            options: [.new])
        { [weak self] _, change in
            if let newValue = change.newValue {
                self?.webContainerView.bottomToolbar.backButton.isEnabled = newValue
            }
        })

        disposeBag.append(webContainerView.webView.observe(\.canGoForward,
                                                            options: [.new])
        { [weak self] _, change in
            if let newValue = change.newValue {
                self?.webContainerView.bottomToolbar.forwardButton.isEnabled = newValue
            }
        })
    }

    // MARK: SearchViewDelegate

    func searchSubmitted(_ text: String) {
        loadQuery(text)
    }

    func searchCleared() {
        reset()
    }

    // MARK: Navigation

    @objc private func didTapBackButtonZZZ() {
        if webContainerView.webView.canGoBack {
            webContainerView.webView.goBack()
        } else {
            reset()
        }
    }

    @objc private func didTapForwardButton() {
        if webContainerView.webView.canGoForward {
            webContainerView.webView.goForward()
        }
    }

    // MARK: StateResettable

    func reset() {
        clearWebViewData {
            DebugLogger.log("Web view data cleared")
            // TODO: Handle asynchronicity of this?
        }
        delegate?.didRequestResetInWebController(self)
    }

    private func clearWebViewData(completion: @escaping () -> Void) {
        let aLongTimeAgo = Date(timeIntervalSinceReferenceDate: 0)
        let dataStore = webContainerView.webView.configuration.websiteDataStore
        dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
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
