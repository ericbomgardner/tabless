import UIKit
import WebKit

class RootViewController: UIViewController, SearchViewDelegate {

    var rootView: RootView! {
        return view as? RootView
    }

    private let stateClearer: StateClearer

    init(stateClearer: StateClearer) {
        self.stateClearer = stateClearer
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(makeSearchViewFirstResponder),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
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
        super.viewWillAppear(animated)
        makeSearchViewFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        makeSearchViewFirstResponder()
    }

    @objc private func makeSearchViewFirstResponder() {
        if !rootView.searchView.isFirstResponder {
            let firstTrySuccess = rootView.searchView.becomeFirstResponder()
            if !firstTrySuccess {
                DispatchQueue.main.async {
                    if !self.rootView.searchView.isFirstResponder {
                        self.rootView.searchView.becomeFirstResponder()
                    }
                }
            }
        }
    }

    // MARK: SearchViewDelegate

    func searchSubmitted(_ text: String) {
        let webViewController = WebViewController(stateClearer: stateClearer)
        webViewController.delegate = self
        webViewController.loadQuery(text)
        navigationController?.pushViewController(webViewController, animated: false) {
            self.rootView.searchView.text = ""
        }
    }

    func searchCleared() {
        UIView.animate(withDuration: 0.35, animations: {
            self.rootView.searchView.becomeFirstResponder()
        })
    }

    // MARK: Sizing

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            // TODO: Resize views
        }, completion: nil)
    }
}

extension RootViewController: WebViewControllerStateResetDelegate {
    func didRequestResetInWebViewController(_ webViewController: WebViewController) {
        navigationController?.popViewController(animated: false)
        rootView.searchView.becomeFirstResponder()
    }
}
