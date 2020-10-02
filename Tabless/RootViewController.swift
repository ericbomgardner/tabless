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

    private let stateClearer: StateClearer

    // Track whether the view has appeared
    //
    // (Between `viewDidAppear` and `viewDidDisappear`)
    private var hasViewAppeared = false

    init(stateClearer: StateClearer) {
        self.stateClearer = stateClearer
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(makeSearchViewFirstResponder),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)

        stateClearer.addStateClearRequest(for: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let rootView = RootView()
        rootView.searchView.searchDelegate = self

        view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        #if DEBUG
        addTTapDetection()
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        makeSearchViewFirstResponder()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasViewAppeared = true
        makeSearchViewFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIResponder.keyboardWillShowNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIResponder.keyboardWillHideNotification,
                                                  object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        hasViewAppeared = false
    }

    func openURL(_ url: URL) {
        // Clean up web view, if it's open
        webView?.removeFromSuperview()
        self.webController = nil

        // Dismiss keyboard, if it's up
        rootView.searchView.resignFirstResponder()

        loadSearch(url.absoluteString)
    }

    @objc private func makeSearchViewFirstResponder() {
        guard webView == nil else {
            // Don't become first responder if web view is up
            return
        }

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

    private func loadSearch(_ text: String) {
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
        clearSearchViewText()
    }

    // MARK: SearchViewDelegate

    func searchSubmitted(_ text: String) {
        loadSearch(text)
    }

    func searchCleared() {
        UIView.animate(withDuration: 0.35, animations: {
            self.rootView.searchView.becomeFirstResponder()
        })
    }

    private func clearSearchViewText() {
        rootView.searchView.text = ""
    }

    // MARK: T view taps

    private func addTTapDetection() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapT))
        rootView.tView.addGestureRecognizer(tapGestureRecognizer)
        rootView.tView.isUserInteractionEnabled = true
    }

    @objc private func didTapT() {
        showAppDebugLogs()
    }

    private func showAppDebugLogs() {
        let navigationController = UINavigationController(rootViewController: DebugLogViewController())
        present(navigationController, animated: true)
    }

    // MARK: Sizing

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            // TODO: Resize views
        }, completion: nil)
    }

    // MARK: Keyboard handling

    @objc private func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let keyboardAnimationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else
        {
            return
        }

        // Ensure that the search view is not obscured by the keyboard
        let keyboardHeight = keyboardFrame.height
        rootView.searchViewBottomConstraint.constant = -keyboardHeight

        // Don't animate if the view hasn't appeared yet -- trying to
        // animating causes everything in the view to animate and
        // look weird.
        guard hasViewAppeared else {
            return
        }

        // Animate the search view constraint change along with the keyboard
        //
        // Notes on handling device rotation:
        // - If the device is rotated, the `keyboardWillShow` notification
        // will be called with a duration of 0, and UIView animations will
        // be disabled. We therefore have to set our own custom animation
        // duration and manually enable animation.
        // - Unfortunately, `keyboardFrameEndUserInfoKey` is not accurate
        // prior to completion of the animation of `viewWillTransition(to size`,
        // so we can't animate `searchViewBottomConstraint.constant` to its
        // appropriate value until `keyboardWillShow` is called, even when
        // trying to use `keyboardWillChangeFrame` notification. See
        // https://stackoverflow.com/questions/49570423/uikeyboard-height-different-after-device-rotation
        // for a question about a similar issue.
        let animationDuration = (keyboardAnimationDuration > 0)
            ? keyboardAnimationDuration
            : 0.2
        let wereAnimationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(true)
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut, animations: {
            self.rootView.layoutIfNeeded()
        }, completion: nil)
        UIView.setAnimationsEnabled(wereAnimationsEnabled)
    }

    @objc private func keyboardWillHide(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else
        {
            return
        }

        self.rootView.searchViewBottomConstraint.constant = 0
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut, animations: {
            self.rootView.layoutIfNeeded()
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

extension RootViewController: StateResettable {
    func reset() {
        clearSearchViewText()
    }
}
