//
//  RootViewController.swift
//  Tabless
//
//  Created by Eric Bomgardner on 3/24/16.
//  Copyright © 2016 Eric Bomgardner. All rights reserved.
//

import UIKit
import WebKit

class RootViewController: UIViewController {

    // MARK: Views
    private let searchView = SearchView()
    private let progressView = ProgressView()
    private var webView = WKWebView()
    private let tView = UITextView()

    // MARK: Constraints
    private var searchYCenterConstraint: NSLayoutConstraint!
    private var searchYTopConstraint: NSLayoutConstraint!
    private var searchHeightConstraint: NSLayoutConstraint!  // TODO: make this automatic
    private var webViewConstraints = [NSLayoutConstraint]()

    // MARK: Saved state
    private var pauseTime: NSDate?

    init() {
        super.init(nibName: nil, bundle: nil)

        searchView.searchDelegate = self

        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:#selector(RootViewController.onPause),
                                                         name:UIApplicationWillResignActiveNotification,
                                                         object:nil)

        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:#selector(RootViewController.onResume),
                                                         name:UIApplicationWillEnterForegroundNotification,
                                                         object:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        tView.text = "T"
        tView.textColor = UIColor.lightGrayColor()
        tView.backgroundColor = UIColor.clearColor()

        view = UIView(frame: UIScreen.mainScreen().bounds)
        view.backgroundColor = UIColor.whiteColor()

        view.addSubview(progressView)
        view.addSubview(tView)
        view.addSubview(searchView)
        view.addSubview(webView)

        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height

        progressView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        progressView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        progressView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        progressView.heightAnchor.constraintEqualToConstant(statusBarHeight + SearchView.height(for: .Web)).active = true

        searchView.leadingAnchor.constraintEqualToAnchor(view.readableContentGuide.leadingAnchor).active = true
        searchView.trailingAnchor.constraintEqualToAnchor(view.readableContentGuide.trailingAnchor).active = true
        searchYCenterConstraint = searchView.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor)
        searchYTopConstraint = searchView.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: statusBarHeight)
        searchHeightConstraint = searchView.heightAnchor.constraintEqualToConstant(SearchView.height(for: .Search))
        searchHeightConstraint.active = true

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

        tView.hidden = false

        webView = WKWebView()
        view.addSubview(webView)
        setUpWebView()

        setUpForSearch()
    }

    func onPause() {
        pauseTime = NSDate()
    }

    func onResume() {
        if let pauseTime = pauseTime where NSDate().timeIntervalSinceDate(pauseTime) > 20 {
            reset()
        }
    }

    deinit {
        removeLoadingKVO()
    }

    // MARK: KVO

    private func setUpLoadingKVO() {
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let newValue = change?[NSKeyValueChangeNewKey] as? NSNumber where keyPath == "estimatedProgress" else {
            return
        }
        progressView.progress = newValue.doubleValue
    }

    private func removeLoadingKVO() {
        webView.removeObserver(self, forKeyPath: "estimatedProgress", context: nil)
    }

    // MARK: Private (Moving Views)

    private func setUpForSearch() {
        let screenBounds = UIScreen.mainScreen().bounds

        searchView.configure(for: .Search)
        searchYTopConstraint.active = false
        searchYCenterConstraint.active = true
        searchHeightConstraint.constant = SearchView.height(for: .Search)

        tView.frame = CGRect(x: (screenBounds.width / 2) - 24, y: 80, width: 48, height: 64)
        tView.font = UIFont.boldSystemFontOfSize(64)

        webView.hidden = true

        searchView.becomeFirstResponder()

        view.layoutIfNeeded()
    }

    private func setUpForWeb() {
        let screenBounds = UIScreen.mainScreen().bounds

        searchView.configure(for: .Web)
        searchYCenterConstraint.active = false
        searchYTopConstraint.active = true
        searchHeightConstraint.constant = SearchView.height(for: .Web)

        tView.frame = CGRect(x: (screenBounds.width / 2) - 24, y: 26, width: 48, height: 32)
        tView.font = UIFont.boldSystemFontOfSize(24)

        view.layoutIfNeeded()
    }

    // MARK: Private (Web view setup)

    func setUpWebView() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self

        applyWebViewConstraints()

        setUpLoadingKVO()
    }

    func applyWebViewConstraints() {
        webViewConstraints.append(webView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor))
        webViewConstraints.append(webView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor))
        webViewConstraints.append(webView.topAnchor.constraintEqualToAnchor(progressView.bottomAnchor))
        webViewConstraints.append(webView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor))
        webViewConstraints.forEach { constraint in
            constraint.active = true
        }
    }

    func clearWebViewConstraints() {
        webViewConstraints.forEach { constraint in
            constraint.active = false
        }
        webViewConstraints.removeAll()
    }
}

extension RootViewController: SearchViewDelegate {
    func searchSubmitted(text: String) {
        self.tView.hidden = true
        UIView.animateWithDuration(0.2, animations: {
            self.setUpForWeb()
        }) { _ in
            self.progressView.hidden = false
        }

        var urlString: String
        if text.isWebURL() {
            urlString = "https://\(text)"
        } else if let searchQuery = text.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
            urlString = "https://www.google.com/search?q=\(searchQuery)"
        } else {
            return
        }
        webView.loadRequest(NSURLRequest(URL: NSURL(string: urlString)!))
    }

    func searchCleared() {
        UIView.animateWithDuration(0.35) {
            self.reset()
        }
    }
}

extension RootViewController: WKNavigationDelegate {
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        webView.hidden = false
//        progressView.hidden = true
    }
}

/// Debugging code (for view hierarchy debugger)
/// TODO: REMOVE THIS!
extension UITextView {
    func _firstBaselineOffsetFromTop() {}
    func _baselineOffsetFromBottom() {}
}
