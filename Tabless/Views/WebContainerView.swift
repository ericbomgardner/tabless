import UIKit
import WebKit

class WebContainerView: UIView {

    let searchView = SearchView()
    let progressView = ProgressView()
    let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()

    init() {
        super.init(frame: .zero)

        backgroundColor = UIColor.white

        addSubview(searchView)
        addSubview(progressView)
        addSubview(webView)
        sendSubview(toBack: progressView)

        searchView.translatesAutoresizingMaskIntoConstraints = false
        searchView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor).isActive = true
        searchView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor).isActive = true
        if #available(iOS 11.0, *) {
            searchView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            searchView.topAnchor.constraint(equalTo: topAnchor,
                                            constant: UIApplication.shared.statusBarFrame.height).isActive = true
        }
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

    func reset() {
        webView.stopLoading()
        progressView.progress = 0
    }

    // MARK: Sizing

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // TODO: Resize search/progress views
    }
}
