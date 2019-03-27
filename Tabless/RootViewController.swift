import UIKit
import WebKit

class RootViewController: UIViewController, SearchViewDelegate {

    var rootView: RootView! {
        return view as? RootView
    }

    var webView: UIView? {
        return webController?.view
    }
    private var webController: WebController? = nil

    private let maxPauseInterval: TimeInterval = 20
    private var pauseTime: Date?

    private let stateClearer: StateClearer

    init(stateClearer: StateClearer) {
        self.stateClearer = stateClearer
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(makeSearchViewFirstResponder),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        setUpKeyboardNotificationObservation()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let rootView = RootView()
        rootView.searchView.searchDelegate = self

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapT))
        rootView.tView.addGestureRecognizer(tapGestureRecognizer)
        rootView.tView.isUserInteractionEnabled = true

        view = rootView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("RVC: viewWillAppear", to: &Logger.shared)
        makeSearchViewFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("RVC: viewDidAppear", to: &Logger.shared)
        makeSearchViewFirstResponder()
    }

    @objc private func makeSearchViewFirstResponder() {
        print("RVC: makeSearchViewFirstResponder, fr: \(firstResponder)", to: &Logger.shared)

        guard webView == nil else {
            // Don't become first responder if web view is up
            print("RVC: web view is up", to: &Logger.shared)
            return
        }

        if !rootView.searchView.isFirstResponder {
            print("RVC: searchView is not first responder", to: &Logger.shared)
            let firstTrySuccess = rootView.searchView.becomeFirstResponder()
            if !firstTrySuccess {
                print("RVC: firstTry failed", to: &Logger.shared)
                DispatchQueue.main.async {
                    if !self.rootView.searchView.isFirstResponder {
                        print("RVC: still not first responder, trying again", to: &Logger.shared)
                        let secondTrySuccess = self.rootView.searchView.becomeFirstResponder()
                        if !secondTrySuccess {
                            print("RVC: secondTry failed", to: &Logger.shared)
                        }
                    }
                }
            }
        }
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
        self.webController = webController
        webController.delegate = self
        webController.loadQuery(text)
        self.rootView.searchView.text = ""
    }

    func searchCleared() {
        UIView.animate(withDuration: 0.35, animations: {
            self.rootView.searchView.becomeFirstResponder()
        })
    }

    // MARK: T view taps

    @objc private func didTapT() {
        let navigationController = UINavigationController(rootViewController: LogViewController())
        present(navigationController, animated: true)
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
        self.webController = nil
        rootView.searchView.becomeFirstResponder()
    }
}

extension RootViewController {
    private func setUpKeyboardNotificationObservation() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidHide),
                                               name: .UIKeyboardDidHide,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidShow),
                                               name: .UIKeyboardDidShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: .UIKeyboardWillHide,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: .UIKeyboardWillShow,
                                               object: nil)
    }

    @objc private func keyboardDidHide() {
        print("RVC: keyboardDidHide, fr: \(firstResponder)", to: &Logger.shared)
    }
    @objc private func keyboardDidShow() {
        print("RVC: keyboardDidShow, fr: \(firstResponder)", to: &Logger.shared)
    }
    @objc private func keyboardWillHide(_ notification: Notification) {
        print("RVC: keyboardWillHide, fr: \(firstResponder)", to: &Logger.shared)
        print("RVC keyboardWillHide, notif: \(notification)", to: &Logger.shared)
        print("RVC keyboardWillHide, stack trace: \(Thread.callStackSymbols)", to: &Logger.shared)

    }
    @objc private func keyboardWillShow() {
        print("RVC: keyboardWillShow, fr: \(firstResponder)", to: &Logger.shared)
    }

    private var firstResponder: UIView? {
        return view.window?.firstResponder
    }
}

extension UIView {
    var firstResponder: UIView? {
        guard !isFirstResponder else { return self }

        for subview in subviews {
            if let firstResponder = subview.firstResponder {
                return firstResponder
            }
        }

        return nil
    }
}
