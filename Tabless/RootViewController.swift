import UIKit
import WebKit

class RootViewController: UIViewController, SearchViewDelegate {

    var rootView: RootView! {
        return view as? RootView
    }

    var webView: UIView? = nil

    private let maxPauseInterval: TimeInterval = 20
    private var pauseTime: Date?

    private let stateClearer: StateClearer

    init(stateClearer: StateClearer) {
        self.stateClearer = stateClearer
        super.init(nibName: nil, bundle: nil)
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

        rootView.searchView.becomeFirstResponder()
    }

    // MARK: SearchViewDelegate

    func searchSubmitted(_ text: String) {
        let webController = WebController(stateClearer: stateClearer)
        let webView = webController.view
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        self.webView = webView
        webController.delegate = self
        webController.loadQuery(text)
        self.rootView.searchView.text = ""
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

extension RootViewController: WebControllerStateResetDelegate {
    func didRequestResetInWebController(_ webController: WebController) {
        webView?.removeFromSuperview()
        rootView.searchView.becomeFirstResponder()
    }
}
