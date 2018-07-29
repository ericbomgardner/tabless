import UIKit
import WebKit

class RootViewController: UIViewController, SearchViewDelegate, StateResettable {

    var mainView: MainView {
        return view as! MainView
    }
    var backSwipeSnapshotView = UIImageView()

    private let maxPauseInterval: TimeInterval = 20
    private var pauseTime: Date?

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
        view = MainView(activity: .search)

        let backSwipeGestureRecognizer =
            UIScreenEdgePanGestureRecognizer(target: self,
                                             action: #selector(handleBackSwipe))
        backSwipeGestureRecognizer.edges = .left
        mainView.addGestureRecognizer(backSwipeGestureRecognizer)

        mainView.searchView.searchDelegate = self
        mainView.webView.navigationDelegate = self
    }

    override func viewDidLoad() {
        setUpLoadingKVO()

        // Delay snapshotting to avoid preventing keyboard entrance
        DispatchQueue.main.async {
            self.setUpBackSwipeSnapshotView()
        }
    }

    deinit {
        removeLoadingKVO()
    }

    // MARK: KVO

    private func setUpLoadingKVO() {
        mainView.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let newValue = change?[NSKeyValueChangeKey.newKey] as? NSNumber,
            keyPath == "estimatedProgress" else
        {
            return
        }
        mainView.progressView.progress = newValue.doubleValue
    }

    private func removeLoadingKVO() {
        mainView.webView.removeObserver(self, forKeyPath: "estimatedProgress", context: nil)
    }

    // MARK: SearchViewDelegate

    func searchSubmitted(_ text: String) {
        mainView.tView.isHidden = true
        UIView.animate(withDuration: 0.2, animations: {
            self.mainView.currentActivity = .web
        }, completion: { _ in
            self.mainView.progressView.isHidden = false
        }) 

        if let url = URLBuilder.createURL(text) {
            mainView.webView.load(URLRequest(url: url))
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
        mainView.reset()
        setUpLoadingKVO()

        clearWebViewData {
            print("Data cleared")
            // TODO: Handle asynchronicity of this?
        }
    }

    private func clearWebViewData(completion: @escaping () -> ()) {
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
            self.mainView.setUpForCurrentActivity()
        }, completion: { _ in
            // TODO: Retake search view snapshot
        })
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
