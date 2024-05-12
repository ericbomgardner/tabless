//
//  WebView.swift
//  Tabless
//
//  Created by Eric Bomgardner on 3/25/23.
//  Copyright © 2023 Eric Bomgardner. All rights reserved.
//

import WebKit

class WebView: WKWebView {
    private let contentBlocker: ContentBlocker

    init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()

        contentBlocker = ContentBlocker(userContentController: configuration.userContentController)

        if UserDefaults.standard.inlineMediaPlayback {
            // Prefer inline media playback, if user has enabled it in settings
            //
            // Prevents auto-playing video (like ads) from taking over the screen
            configuration.allowsInlineMediaPlayback = true
        }

        super.init(frame: .zero, configuration: configuration)

        scrollView.decelerationRate = .normal
        allowsBackForwardNavigationGestures = true

        contentBlocker.setUpBlocklists()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
