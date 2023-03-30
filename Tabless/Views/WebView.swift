//
//  WebView.swift
//  Tabless
//
//  Created by Eric Bomgardner on 3/25/23.
//  Copyright © 2023 Eric Bomgardner. All rights reserved.
//

import WebKit

class WebView: WKWebView {
    init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()

        super.init(frame: .zero, configuration: configuration)

        scrollView.decelerationRate = .normal
        allowsBackForwardNavigationGestures = true

        setUpBlocklist()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUpBlocklist() {
        guard UserDefaults.standard.isContentBlockingEnabled else {
            return
        }

        Task {
            let blocklist = await BlocklistProvider.getBlocklist()
            configuration.userContentController.add(blocklist)
        }
    }
}
