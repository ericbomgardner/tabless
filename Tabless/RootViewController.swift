import UIKit
import WebKit

class RootViewController: UIViewController, SearchViewDelegate, StateResettable {

    var rootView: RootView! {
        return view as! RootView
    }
    var webContainerView: WebContainerView?

    var webContainerViewLeadingConstraint: NSLayoutConstraint?
    var webContainerViewTrailingConstraint: NSLayoutConstraint?

    private let maxPauseInterval: TimeInterval = 20
    private var pauseTime: Date?

    private var webViewProgressObservationToken: NSKeyValueObservation?

    private let stateClearer: StateClearer

    init(stateClearer: StateClearer) {
        self.stateClearer = stateClearer
        super.init(nibName: nil, bundle: nil)

        stateClearer.addStateClearRequest(for: self,
                                          after: maxPauseInterval)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let rootView = RootView()
        rootView.searchView.searchDelegate = self

        view = rootView
    }

    override func viewWillAppear(_ animated: Bool) {
        rootView.searchView.becomeFirstResponder()
    }

    deinit {
        removeLoadingKVO()
    }

    // MARK: Transitioning

    private func transitionToWebContainerView() {
        let webContainerView = WebContainerView()
        self.webContainerView = webContainerView
        webContainerView.translatesAutoresizingMaskIntoConstraints = false
        webContainerView.preservesSuperviewLayoutMargins = true
        let backSwipeGestureRecognizer =
            UIScreenEdgePanGestureRecognizer(target: self,
                                             action: #selector(handleBackSwipe))
        backSwipeGestureRecognizer.edges = .left
        webContainerView.addGestureRecognizer(backSwipeGestureRecognizer)
        webContainerView.webView.navigationDelegate = self
        webContainerView.searchView.searchDelegate = self
        view.addSubview(webContainerView)

        let webContainerViewLeadingConstraint = webContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        webContainerViewLeadingConstraint.isActive = true
        self.webContainerViewLeadingConstraint = webContainerViewLeadingConstraint
        webContainerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        webContainerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        rootView.searchView.text = ""

        setUpLoadingKVO()
    }

    // MARK: KVO

    private func setUpLoadingKVO() {
        webViewProgressObservationToken = webContainerView?.webView.observe(\.estimatedProgress,
                                                                            options: [.new])
        { [weak self] _, change in
            if let newValue = change.newValue {
                self?.webContainerView?.progressView.progress = newValue
            }
        }
    }

    private func removeLoadingKVO() {
        webViewProgressObservationToken = nil
    }

    // MARK: SearchViewDelegate

    func searchSubmitted(_ text: String) {
        transitionToWebContainerView()

        if let url = URLBuilder.createURL(text) {
            webContainerView?.searchView.text = text
            webContainerView?.webView.load(URLRequest(url: url))
        }
    }

    func searchCleared() {
        UIView.animate(withDuration: 0.35, animations: {
            self.reset()
        })
    }

    // MARK: StateResettable

    func reset() {
        removeLoadingKVO()
        webContainerViewLeadingConstraint = nil
        webContainerView?.removeFromSuperview()
        webContainerView = nil

        clearWebViewData {
            print("Data cleared")
            // TODO: Handle asynchronicity of this?
        }
        rootView.searchView.becomeFirstResponder()
    }

    private func clearWebViewData(completion: @escaping () -> Void) {
        let aLongTimeAgo = Date(timeIntervalSinceReferenceDate: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                                modifiedSince: aLongTimeAgo) {
            completion()
        }
    }

    // MARK: Sizing

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            // TODO: Resize views
        }, completion: nil)
    }
}

extension RootViewController: WKNavigationDelegate {
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
