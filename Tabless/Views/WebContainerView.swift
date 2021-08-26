import UIKit
import WebKit

/// Container for search, progress, and web views (and toolbar)
class WebContainerView: UIView {

    let searchViewContainer = UIView()
    let searchView = SearchView()
    let progressView = ProgressView()
    let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.scrollView.decelerationRate = .normal
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()
    let bottomToolbarContainer = UIView()
    let bottomToolbar = WebToolbar()

    struct SearchViewTextInset {
        static let inset = 12
    }

    init() {
        super.init(frame: .zero)

        backgroundColor = UIColor(named: "Background")

        addSubview(webView)

        searchViewContainer.translatesAutoresizingMaskIntoConstraints = false
        searchViewContainer.backgroundColor = .white
        searchViewContainer.addSubtleShadow()
        addSubview(searchViewContainer)
        searchViewContainer.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        searchViewContainer.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        searchViewContainer.topAnchor.constraint(equalTo: topAnchor).isActive = true

        searchViewContainer.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.leadingAnchor.constraint(equalTo: searchViewContainer.leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: searchViewContainer.trailingAnchor).isActive = true
        progressView.topAnchor.constraint(equalTo: searchViewContainer.topAnchor).isActive = true
        progressView.bottomAnchor.constraint(equalTo: searchViewContainer.bottomAnchor).isActive = true

        searchView.translatesAutoresizingMaskIntoConstraints = false
        searchViewContainer.addSubview(searchView)

        // Ensure that search view has enough leading and trailing padding (minimum of 16),
        // is never wider than the readable content guide says it should be, but otherwise
        // uses all of the space available
        let minimumPaddingBetweenSearchViewAndViewEdge: CGFloat = 16
        let leadingPaddingConstraint = searchView.leadingAnchor.constraint(greaterThanOrEqualTo: searchViewContainer.leadingAnchor)
        leadingPaddingConstraint.constant = minimumPaddingBetweenSearchViewAndViewEdge
        leadingPaddingConstraint.isActive = true
        let trailingPaddingConstraint = searchView.trailingAnchor.constraint(lessThanOrEqualTo: searchViewContainer.trailingAnchor)
        trailingPaddingConstraint.constant = -minimumPaddingBetweenSearchViewAndViewEdge
        trailingPaddingConstraint.isActive = true

        let leadingOptionalConstraint = searchView.leadingAnchor.constraint(equalTo: searchViewContainer.leadingAnchor)
        leadingOptionalConstraint.constant = minimumPaddingBetweenSearchViewAndViewEdge
        leadingOptionalConstraint.priority = UILayoutPriority.defaultHigh
        leadingOptionalConstraint.isActive = true
        let trailingOptionalConstraint = searchView.trailingAnchor.constraint(equalTo: searchViewContainer.trailingAnchor)
        trailingOptionalConstraint.constant = minimumPaddingBetweenSearchViewAndViewEdge
        trailingOptionalConstraint.priority = UILayoutPriority.defaultHigh
        trailingOptionalConstraint.isActive = true

        let leadingContentGuideConstraint = searchView.leadingAnchor.constraint(equalTo: searchViewContainer.leadingAnchor)
        leadingContentGuideConstraint.priority = UILayoutPriority.defaultLow
        leadingContentGuideConstraint.isActive = true
        let trailingContentGuideConstraint = searchView.trailingAnchor.constraint(lessThanOrEqualTo: searchViewContainer.trailingAnchor)
        trailingContentGuideConstraint.priority = UILayoutPriority.defaultLow
        trailingContentGuideConstraint.isActive = true

        searchView.leadingAnchor.constraint(greaterThanOrEqualTo: searchViewContainer.readableContentGuide.leadingAnchor).isActive = true
        searchView.trailingAnchor.constraint(lessThanOrEqualTo: searchViewContainer.readableContentGuide.trailingAnchor).isActive = true

        searchView.topAnchor.constraint(equalTo: searchViewContainer.safeAreaLayoutGuide.topAnchor).isActive = true
        searchView.heightAnchor.constraint(equalToConstant: searchView.height(for: .web)).isActive = true
        searchView.bottomAnchor.constraint(equalTo: searchViewContainer.bottomAnchor).isActive = true
        searchView.configure(for: .web)

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: progressView.bottomAnchor).isActive = true

        bottomToolbarContainer.backgroundColor = .white
        bottomToolbarContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomToolbarContainer)
        bottomToolbarContainer.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        bottomToolbarContainer.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        bottomToolbarContainer.topAnchor.constraint(equalTo: webView.bottomAnchor).isActive = true
        bottomToolbarContainer.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        bottomToolbarContainer.addSubtleShadow()
        bottomToolbarContainer.addSubview(bottomToolbar)
        bottomToolbar.leadingAnchor.constraint(equalTo: bottomToolbarContainer.leadingAnchor).isActive = true
        bottomToolbar.trailingAnchor.constraint(equalTo: bottomToolbarContainer.trailingAnchor).isActive = true
        bottomToolbar.topAnchor.constraint(equalTo: bottomToolbarContainer.topAnchor).isActive = true
        bottomToolbar.bottomAnchor.constraint(equalTo: bottomToolbarContainer.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        searchViewContainer.layer.shadowPath = UIBezierPath(rect: searchViewContainer.bounds).cgPath
        bottomToolbarContainer.layer.shadowPath = UIBezierPath(rect: bottomToolbarContainer.bounds).cgPath
    }

    // MARK: Sizing

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // TODO: Resize search/progress views
    }
}

private extension UIView {
    func addSubtleShadow() {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowOpacity = 0.22
        layer.shadowOffset = .zero
        layer.shadowRadius = 6
    }
}
