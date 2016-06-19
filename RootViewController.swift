//
//  RootViewController.swift
//  Tabless
//
//  Created by Eric Bomgardner on 3/24/16.
//  Copyright © 2016 Eric Bomgardner. All rights reserved.
//

import UIKit
import WebKit

class RootViewController: UIViewController, UITextFieldDelegate, WKNavigationDelegate {

  private let searchView = UITextField()
  private let progressView = UIView()
  private var webView: WKWebView = WKWebView()
  private let tView = UITextView()

  private var pauseTime: NSDate?

  override func loadView() {
    setUpForSearch()

    tView.text = "T"
    tView.textColor = UIColor.lightGrayColor()
    tView.backgroundColor = UIColor.clearColor()

    progressView.backgroundColor = UIColor.lightGrayColor()

    let containerView = UIView(frame: UIScreen.mainScreen().bounds)
    containerView.backgroundColor = UIColor.whiteColor()

    containerView.addSubview(progressView)
    containerView.addSubview(tView)
    containerView.addSubview(searchView)
    containerView.addSubview(webView)
    setUpLoadingKVO()

    NSNotificationCenter.defaultCenter().addObserver(self,
                                                     selector:#selector(RootViewController.onPause),
                                                     name:UIApplicationWillResignActiveNotification,
                                                     object:nil)

    NSNotificationCenter.defaultCenter().addObserver(self,
                                                     selector:#selector(RootViewController.onResume),
                                                     name:UIApplicationWillEnterForegroundNotification,
                                                     object:nil)

    view = containerView
  }

  func reset() {
    removeLoadingKVO()
    webView.removeFromSuperview()

    tView.hidden = false
    setUpForSearch()

    webView = WKWebView()
    view.addSubview(webView)
    setUpLoadingKVO()
  }

  func onPause() {
    pauseTime = NSDate()
  }

  func onResume() {
    if let pauseTime = pauseTime {
      if NSDate().timeIntervalSinceDate(pauseTime) > 20 {
        reset()
      }
    }
  }

  deinit {
    removeLoadingKVO()
  }

  // MARK: UITextFieldDelegate

  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()

    self.tView.hidden = true
    UIView.animateWithDuration(0.2, animations: { 
      self.setUpForWeb()
    }) { _ in
      self.progressView.hidden = false
    }

    return false
  }

  func textFieldDidEndEditing(textField: UITextField) {
    guard let text = textField.text else {
      return
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

  func textFieldShouldClear(textField: UITextField) -> Bool {
    webView.stopLoading()

    self.tView.hidden = false
    UIView.animateWithDuration(0.35) {
      self.reset()
    }

    return true
  }

  // MARK: UINavigationDelegate

  func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
    self.webView.hidden = false
    progressView.hidden = true
  }

  // MARK: KVO

  @objc private func setUpLoadingKVO() {
    webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
  }

  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    guard keyPath == "estimatedProgress" else {
      return
    }

    if let newValue = change?[NSKeyValueChangeNewKey] as? NSNumber {
      updateProgressView(newValue.doubleValue)
    }
  }

  private func removeLoadingKVO() {
    webView.removeObserver(self, forKeyPath: "estimatedProgress", context: nil)
  }

  // MARK: Private (Moving Views)

  private func setUpForSearch() {
    let screenBounds = UIScreen.mainScreen().bounds

    searchView.frame = CGRect(x: 12, y: (screenBounds.height / 2) - 40, width: screenBounds.width - 24, height: 40)
    searchView.returnKeyType = .Go
    searchView.text = ""
    searchView.placeholder = "Let's go."
    searchView.font = UIFont.systemFontOfSize(30)
    searchView.delegate = self

    tView.frame = CGRect(x: (screenBounds.width / 2) - 24, y: 80, width: 48, height: 64)
    tView.font = UIFont.boldSystemFontOfSize(64)

    webView.hidden = true
    webView.frame = CGRect(x: 0, y: 60, width: screenBounds.width, height: screenBounds.height - 60)
    webView.navigationDelegate = self
    webView.allowsBackForwardNavigationGestures = true

    searchView.becomeFirstResponder()
  }

  private func setUpForWeb() {
    let screenBounds = UIScreen.mainScreen().bounds

    searchView.frame = CGRect(x: 12, y: 20, width: screenBounds.width - 24, height: 40)
    searchView.font = UIFont.systemFontOfSize(14)
    searchView.clearButtonMode = UITextFieldViewMode.Always

    tView.frame = CGRect(x: (screenBounds.width / 2) - 24, y: 26, width: 48, height: 32)
    tView.font = UIFont.boldSystemFontOfSize(24)

    webView.frame = CGRect(x: 0, y: 60, width: screenBounds.width, height: screenBounds.height - 60)
  }

  private func updateProgressView(progress: Double) {
    let loadedArea = CGRect(x: 0, y: 0, width: CGFloat(progress) * UIScreen.mainScreen().bounds.width, height: 60)

    UIView.animateWithDuration(0.5, delay: 0.0, options: .BeginFromCurrentState, animations: { 
      self.progressView.frame = loadedArea
    }) { (_) in
      if (progress == 1) {
        UIView.animateWithDuration(0.5, animations: {
          self.progressView.alpha = 0.0
        }, completion: { (_) in
          self.progressView.frame = CGRect(x: 0, y: 0, width: 0, height: 60)
          self.progressView.alpha = 1.0
        })
      }
    }
  }
}

extension String {

  func isWebURL() -> Bool {
    return hasPrefix("www.") || containsString(".com") || containsString(".net")
  }
}
