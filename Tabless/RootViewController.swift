import UIKit
import WebKit

class RootViewController: UIViewController, SearchViewDelegate, StateResettable {
    private var currentActivity: Activity {
        if webView.isHidden {
            return .search
        } else {
            return .web
        }
    }

    // MARK: Views
    let searchView = SearchView()
    var searchViewSnapshotView = UIImageView()
    private let progressView = ProgressView()
    var webView: WKWebView!
    private let tView = UITextView()

    // MARK: Constraints
    var searchLeadingConstraint: NSLayoutConstraint!
    var searchTrailingConstraint: NSLayoutConstraint!
    private var searchYCenterConstraint: NSLayoutConstraint!
    private var searchYTopConstraint: NSLayoutConstraint!
    private var searchHeightConstraint: NSLayoutConstraint!  // TODO: make this automatic
    var webViewConstraints = [NSLayoutConstraint]()

    // MARK: Constants
    private let maxPauseInterval: TimeInterval = 20

    // MARK: Saved state
    private var pauseTime: Date?

    // MARK: Dependencies
    private let stateClearer: StateClearer

    init(stateClearer: StateClearer) {
        self.stateClearer = stateClearer
        super.init(nibName: nil, bundle: nil)

        webView = createWebView()

        searchView.searchDelegate = self
        stateClearer.addStateClearRequest(for: self,
                                          after: maxPauseInterval)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        tView.text = "T"
        tView.textColor = UIColor.lightGray
        tView.backgroundColor = UIColor.clear

        view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = UIColor.white
        let backSwipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleBackSwipe))
        backSwipeGestureRecognizer.edges = .left
        view.addGestureRecognizer(backSwipeGestureRecognizer)

        view.addSubview(progressView)
        view.addSubview(tView)
        view.addSubview(searchView)
        view.addSubview(webView)

        let statusBarHeight = UIApplication.shared.statusBarFrame.height

        progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        progressView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: statusBarHeight + searchView.height(for: .web)).isActive = true

        searchLeadingConstraint = searchView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor)
        searchLeadingConstraint.isActive = true
        searchTrailingConstraint = searchView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor)
        searchTrailingConstraint.isActive = true
        searchYCenterConstraint = searchView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        searchYTopConstraint = searchView.topAnchor.constraint(equalTo: view.topAnchor, constant: statusBarHeight)
        searchHeightConstraint = searchView.heightAnchor.constraint(equalToConstant: searchView.height(for: .search))
        searchHeightConstraint.isActive = true

        setUpWebView()
    }

    override func viewDidLoad() {
        setUpForSearch()

        // Delay snapshotting to avoid preventing keyboard entrance
        DispatchQueue.main.async {
            self.setUpSearchViewSnapshotView()
        }
    }

    func reset() {
        webView.stopLoading()
        removeLoadingKVO()
        clearWebViewConstraints()
        webView.removeFromSuperview()

        progressView.progress = 0

        tView.isHidden = false

        webView = createWebView()
        view.addSubview(webView)
        setUpWebView()

        setUpForSearch()

        clearWebViewData {
            print("Data cleared")
            // TODO: Handle asynchronicity of this?
        }
    }

    deinit {
        removeLoadingKVO()
    }

    // MARK: KVO

    private func setUpLoadingKVO() {
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let newValue = change?[NSKeyValueChangeKey.newKey] as? NSNumber, keyPath == "estimatedProgress" else {
            return
        }
        progressView.progress = newValue.doubleValue
    }

    private func removeLoadingKVO() {
        webView.removeObserver(self, forKeyPath: "estimatedProgress", context: nil)
    }

    // MARK: Private (Moving Views)

    private func setUpForSearch() {
        let screenBounds = UIScreen.main.bounds

        searchView.configure(for: .search)
        searchYTopConstraint.isActive = false
        searchYCenterConstraint.isActive = true
        searchHeightConstraint.constant = searchView.height(for: .search)

        let tViewSize: CGFloat = traitCollection.isLarge ? 80 : 64
        tView.frame = CGRect(x: (screenBounds.width / 2) - 24,
                             y: 80,
                             width: tViewSize,
                             height: tViewSize)
        tView.font = UIFont.boldSystemFont(ofSize: tViewSize)

        webView.isHidden = true

        searchView.becomeFirstResponder()

        view.layoutIfNeeded()
    }

    private func setUpForWeb() {
        let screenBounds = UIScreen.main.bounds

        searchView.configure(for: .web)
        searchYCenterConstraint.isActive = false
        searchYTopConstraint.isActive = true
        searchHeightConstraint.constant = searchView.height(for: .web)

        let tViewSize: CGFloat = traitCollection.isLarge ? 30 : 24
        tView.frame = CGRect(x: (screenBounds.width / 2) - 24,
                             y: 26,
                             width: tViewSize,
                             height: tViewSize)
        tView.font = UIFont.boldSystemFont(ofSize: tViewSize)

        webView.isHidden = false

        view.layoutIfNeeded()
    }

    // MARK: Private (Web view setup)

    private func createWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        return webView
    }

    private func setUpWebView() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self

        applyWebViewConstraints()

        setUpLoadingKVO()
    }

    private func applyWebViewConstraints() {
        webViewConstraints.append(webView.leadingAnchor.constraint(equalTo: view.leadingAnchor))
        webViewConstraints.append(webView.widthAnchor.constraint(equalTo: view.widthAnchor))
        webViewConstraints.append(webView.topAnchor.constraint(equalTo: progressView.bottomAnchor))
        webViewConstraints.append(webView.bottomAnchor.constraint(equalTo: view.bottomAnchor))
        webViewConstraints.forEach { constraint in
            constraint.isActive = true
        }
    }

    private func clearWebViewConstraints() {
        webViewConstraints.forEach { constraint in
            constraint.isActive = false
        }
        webViewConstraints.removeAll()
    }

    private func clearWebViewData(completion: @escaping () -> ()) {
        let aLongTimeAgo = Date(timeIntervalSinceReferenceDate: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                                modifiedSince: aLongTimeAgo) {
            completion()
        }
    }

    // MARK: Search view snapshot view setup

    private func setUpSearchViewSnapshotView() {
        searchViewSnapshotView.image = view.toSnapshot()
        searchViewSnapshotView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchViewSnapshotView)
        view.sendSubview(toBack: searchViewSnapshotView)
        searchViewSnapshotView.pinEdgesToSuperviewEdges()

        searchViewSnapshotView.isHidden = true
    }

    private func retakeSearchViewSnaphot() {
        searchViewSnapshotView.image = view.toSnapshot()
    }

    // MARK: SearchViewDelegate

    func searchSubmitted(_ text: String) {
        tView.isHidden = true
        UIView.animate(withDuration: 0.2, animations: {
            self.setUpForWeb()
        }, completion: { _ in
            self.progressView.isHidden = false
        }) 

        if let url = URLBuilder.createURL(text) {
            webView.load(URLRequest(url: url))
        }
    }

    func searchCleared() {
        UIView.animate(withDuration: 0.35, animations: {
            self.reset()
        }) 
    }

    // MARK: Sizing

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        switch currentActivity {
        case .search:
            setUpForSearch()
        case .web:
            setUpForWeb()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            switch self.currentActivity {
            case .search:
                self.setUpForSearch()
            case .web:
                self.setUpForWeb()
            }
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
