import UIKit
import WebKit

/// Container for search, progress, and web views
class WebContainerView: UIView {

    let searchView = SearchView()
    let progressView = ProgressView()
    let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.scrollView.decelerationRate = .normal
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()

    struct SearchViewTextInset {
        static let inset = 12
    }

    init() {
        super.init(frame: .zero)

        backgroundColor = UIColor.white

        addSubview(searchView)
        addSubview(progressView)
        progressView.alpha = 0.3
        addSubview(webView)
        sendSubviewToBack(progressView)

        searchView.translatesAutoresizingMaskIntoConstraints = false
        searchView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor).isActive = true
        searchView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor).isActive = true
        searchView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        searchView.heightAnchor.constraint(equalToConstant: searchView.height(for: .web)).isActive = true
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
