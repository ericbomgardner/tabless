//
//  BlocklistProvider.swift
//  Tabless
//
//  Created by Eric Bomgardner on 3/29/23.
//  Copyright © 2023 Eric Bomgardner. All rights reserved.
//

import WebKit

class BlocklistProvider {
    static func getBlocklist() async -> WKContentRuleList {
        let blocklistPath = Bundle.main.path(forResource: "blocklist", ofType: "json")!
        let blocklistJson = try! String(contentsOfFile: blocklistPath, encoding: String.Encoding.utf8)
        return try! await WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "blocklist", encodedContentRuleList: blocklistJson)!
    }
}
