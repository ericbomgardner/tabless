import UIKit
import WebKit

class MainView: UIView {

    var currentActivity: Activity {
        didSet {
            setUpForCurrentActivity()
        }
    }

    let searchView = SearchView()
    let progressView = ProgressView()
    var webView: WKWebView!
    let tView = UILabel()

    private var tViewTopConstraint: NSLayoutConstraint!
    var searchLeadingConstraint: NSLayoutConstraint!
    var searchTrailingConstraint: NSLayoutConstraint!
    private var searchYCenterConstraint: NSLayoutConstraint!
    private var searchYTopConstraint: NSLayoutConstraint!
    private var searchHeightConstraint: NSLayoutConstraint!  // TODO: make this automatic
    var webViewConstraints = [NSLayoutConstraint]()

    init(activity: Activity) {
        currentActivity = activity

        super.init(frame: .zero)

        tView.text = "T"
        tView.textColor = UIColor.lightGray
        tView.backgroundColor = UIColor.clear

        backgroundColor = UIColor.white

        addSubview(progressView)
        addSubview(tView)
        addSubview(searchView)
        createWebView()
        addSubview(webView)

        let statusBarHeight = UIApplication.shared.statusBarFrame.height

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        progressView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: statusBarHeight + searchView.height(for: .web)).isActive = true

        tView.translatesAutoresizingMaskIntoConstraints = false
        tViewTopConstraint = tView.topAnchor.constraint(equalTo: topAnchor, constant: 0)
        tViewTopConstraint.isActive = true
        tView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

        searchView.translatesAutoresizingMaskIntoConstraints = false
        searchLeadingConstraint = searchView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor)
        searchLeadingConstraint.isActive = true
        searchTrailingConstraint = searchView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor)
        searchTrailingConstraint.isActive = true
        searchYCenterConstraint = searchView.centerYAnchor.constraint(equalTo: centerYAnchor)
        searchYTopConstraint = searchView.topAnchor.constraint(equalTo: topAnchor, constant: statusBarHeight)
        searchHeightConstraint = searchView.heightAnchor.constraint(equalToConstant: searchView.height(for: .search))
        searchHeightConstraint.isActive = true

        applyWebViewConstraints()

        setUpForCurrentActivity()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        webView.stopLoading()
        progressView.progress = 0
        tView.isHidden = false

        // Re-create web view to reset back stack
        recreateWebView()

        currentActivity = .search
    }

    // MARK: Moving Views

    func setUpForCurrentActivity() {
        switch currentActivity {
        case .search:
            setUpForSearch()
        case .web:
            setUpForWeb()
        }
    }

    private func setUpForSearch() {
        searchView.configure(for: .search)
        searchYTopConstraint.isActive = false
        searchYCenterConstraint.isActive = true
        searchHeightConstraint.constant = searchView.height(for: .search)

        let tViewSize: CGFloat = traitCollection.isLarge ? 80 : 64
        tView.font = UIFont.boldSystemFont(ofSize: tViewSize)
        tViewTopConstraint.constant = 80

        webView.isHidden = true

        searchView.becomeFirstResponder()

        layoutIfNeeded()
    }

    private func setUpForWeb() {
        searchView.configure(for: .web)
        searchYCenterConstraint.isActive = false
        searchYTopConstraint.isActive = true
        searchHeightConstraint.constant = searchView.height(for: .web)

        let tViewSize: CGFloat = traitCollection.isLarge ? 30 : 24
        tView.font = UIFont.boldSystemFont(ofSize: tViewSize)
        tViewTopConstraint.constant = 26

        webView.isHidden = false

        layoutIfNeeded()
    }

    // MARK: Private (Web view setup)

    private func createWebView() {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        self.webView = webView
    }

    private func recreateWebView() {
        clearWebViewConstraints()
        webView.removeFromSuperview()
        createWebView()
        addSubview(webView)
        applyWebViewConstraints()
    }

    private func applyWebViewConstraints() {
        webViewConstraints.append(webView.leadingAnchor.constraint(equalTo: leadingAnchor))
        webViewConstraints.append(webView.widthAnchor.constraint(equalTo: widthAnchor))
        webViewConstraints.append(webView.topAnchor.constraint(equalTo: progressView.bottomAnchor))
        webViewConstraints.append(webView.bottomAnchor.constraint(equalTo: bottomAnchor))
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

    // MARK: Sizing

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setUpForCurrentActivity()
    }
}
