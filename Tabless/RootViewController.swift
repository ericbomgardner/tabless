import UIKit
import WebKit

class RootViewController: UIViewController, SearchViewDelegate, StateResettable {

    var rootView: RootView! {
        return view as? RootView
    }

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
        let rootView = RootView()
        rootView.searchView.searchDelegate = self

        view = rootView
    }

    override func viewWillAppear(_ animated: Bool) {
        rootView.searchView.becomeFirstResponder()
    }

    // MARK: SearchViewDelegate

    func searchSubmitted(_ text: String) {
        let webViewController = WebViewController(stateClearer: stateClearer)
        present(webViewController, animated: false) {
            webViewController.loadQuery(text)
        }

        rootView.searchView.text = ""
    }

    func searchCleared() {
        UIView.animate(withDuration: 0.35, animations: {
            self.reset()
        })
    }

    // MARK: StateResettable

    func reset() {
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
