import UIKit
import WebKit

/// Container for search, progress, and web views
class WebContainerView: UIView {

    let searchView = SearchView()
    let progressView = ProgressView()
    let webView: WKWebView = WebView()

    struct SearchViewTextInset {
        static let inset = 12
    }

    init() {
        super.init(frame: .zero)

        backgroundColor = UIColor(named: "Background")

        addSubview(searchView)
        addSubview(progressView)
        progressView.alpha = 0.3
        addSubview(webView)
        sendSubviewToBack(progressView)

        searchView.translatesAutoresizingMaskIntoConstraints = false

        // Ensure that search view has enough leading and trailing padding (minimum of 16),
        // is never wider than the readable content guide says it should be, but otherwise
        // uses all of the space available
        let minimumPaddingBetweenSearchViewAndViewEdge: CGFloat = 16
        let leadingPaddingConstraint = searchView.leadingAnchor.constraint(
            greaterThanOrEqualTo: leadingAnchor)
        leadingPaddingConstraint.constant = minimumPaddingBetweenSearchViewAndViewEdge
        leadingPaddingConstraint.isActive = true
        let trailingPaddingConstraint = searchView.trailingAnchor.constraint(
            lessThanOrEqualTo: trailingAnchor)
        trailingPaddingConstraint.constant = -minimumPaddingBetweenSearchViewAndViewEdge
        trailingPaddingConstraint.isActive = true

        let leadingOptionalConstraint = searchView.leadingAnchor.constraint(equalTo: leadingAnchor)
        leadingOptionalConstraint.constant = minimumPaddingBetweenSearchViewAndViewEdge
        leadingOptionalConstraint.priority = UILayoutPriority.defaultHigh
        leadingOptionalConstraint.isActive = true
        let trailingOptionalConstraint = searchView.trailingAnchor.constraint(
            equalTo: trailingAnchor)
        trailingOptionalConstraint.constant = minimumPaddingBetweenSearchViewAndViewEdge
        trailingOptionalConstraint.priority = UILayoutPriority.defaultHigh
        trailingOptionalConstraint.isActive = true

        let leadingContentGuideConstraint = searchView.leadingAnchor.constraint(
            equalTo: leadingAnchor)
        leadingContentGuideConstraint.priority = UILayoutPriority.defaultLow
        leadingContentGuideConstraint.isActive = true
        let trailingContentGuideConstraint = searchView.trailingAnchor.constraint(
            lessThanOrEqualTo: trailingAnchor)
        trailingContentGuideConstraint.priority = UILayoutPriority.defaultLow
        trailingContentGuideConstraint.isActive = true

        searchView.leadingAnchor.constraint(
            greaterThanOrEqualTo: readableContentGuide.leadingAnchor
        ).isActive = true
        searchView.trailingAnchor.constraint(lessThanOrEqualTo: readableContentGuide.trailingAnchor)
            .isActive = true

        searchView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        searchView.heightAnchor.constraint(equalToConstant: searchView.height(for: .web)).isActive =
            true
        searchView.configure(for: .web)

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        progressView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        progressView.bottomAnchor.constraint(equalTo: searchView.bottomAnchor).isActive = true

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: progressView.bottomAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Sizing

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // TODO: Resize search/progress views
    }
}
