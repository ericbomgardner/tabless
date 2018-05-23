import UIKit
import WebKit

class RootViewController: UIViewController, SearchViewDelegate, StateResettable {
    // MARK: Views
    private let searchView = SearchView()
    private let progressView = ProgressView()
    private var webView: WKWebView!
    private let tView = UITextView()

    // MARK: Constraints
    private var searchYCenterConstraint: NSLayoutConstraint!
    private var searchYTopConstraint: NSLayoutConstraint!
    private var searchHeightConstraint: NSLayoutConstraint!  // TODO: make this automatic
    private var webViewConstraints = [NSLayoutConstraint]()

    // MARK: Constants
    private let maxPauseInterval: TimeInterval = 20
    private let searchURLBase = "https://www.google.com/search?q="

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
        progressView.heightAnchor.constraint(equalToConstant: statusBarHeight + SearchView.height(for: .web)).isActive = true

        searchView.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor).isActive = true
        searchView.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor).isActive = true
        searchYCenterConstraint = searchView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        searchYTopConstraint = searchView.topAnchor.constraint(equalTo: view.topAnchor, constant: statusBarHeight)
        searchHeightConstraint = searchView.heightAnchor.constraint(equalToConstant: SearchView.height(for: .search))
        searchHeightConstraint.isActive = true

        setUpWebView()
    }

    override func viewDidLoad() {
        setUpForSearch()
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
        searchHeightConstraint.constant = SearchView.height(for: .search)

        tView.frame = CGRect(x: (screenBounds.width / 2) - 24, y: 80, width: 48, height: 64)
        tView.font = UIFont.boldSystemFont(ofSize: 64)

        webView.isHidden = true

        searchView.becomeFirstResponder()

        view.layoutIfNeeded()
    }

    private func setUpForWeb() {
        let screenBounds = UIScreen.main.bounds

        searchView.configure(for: .web)
        searchYCenterConstraint.isActive = false
        searchYTopConstraint.isActive = true
        searchHeightConstraint.constant = SearchView.height(for: .web)

        tView.frame = CGRect(x: (screenBounds.width / 2) - 24, y: 26, width: 48, height: 32)
        tView.font = UIFont.boldSystemFont(ofSize: 24)

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
        webViewConstraints.append(webView.trailingAnchor.constraint(equalTo: view.trailingAnchor))
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

    // MARK: SearchViewDelegate

    func searchSubmitted(_ text: String) {
        tView.isHidden = true
        UIView.animate(withDuration: 0.2, animations: {
            self.setUpForWeb()
        }, completion: { _ in
            self.progressView.isHidden = false
        }) 

        var urlString: String
        if text.isWebURL() {
            urlString = "https://\(text)"
        } else if let searchQuery = text.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
            urlString = "\(searchURLBase)\(searchQuery)"
        } else {
            return
        }
        webView.load(URLRequest(url: URL(string: urlString)!))
    }

    func searchCleared() {
        UIView.animate(withDuration: 0.35, animations: {
            self.reset()
        }) 
    }

    // MARK: UIScreenEdgePanGestureRecognizer callback

    @objc func handleBackSwipe(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        // TODO: Handle back swipe on first page to go back to search
    }
}

extension RootViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.isHidden = false
    }
}

/// Debugging code (for view hierarchy debugger)
/// TODO: REMOVE THIS!
extension UITextView {
    func _firstBaselineOffsetFromTop() {}
    func _baselineOffsetFromBottom() {}
}
