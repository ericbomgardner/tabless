//
//  String+WebURL.swift
//  Tabless
//
//  Created by Eric Bomgardner on 6/18/16.
//  Copyright © 2016 Eric Bomgardner. All rights reserved.
//

extension String {
    func isWebURL() -> Bool {
        return hasPrefix("www.") || containsString(".com") || containsString(".net") || containsString(".org")
    }
}
