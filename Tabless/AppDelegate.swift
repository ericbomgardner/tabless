//
//  AppDelegate.swift
//  Tabless
//
//  Created by Eric Bomgardner on 11/9/15.
//  Copyright © 2015 Eric Bomgardner. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let rootViewController = RootViewController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = rootViewController
        self.window = window

        window.makeKeyAndVisible()

        return true
    }
}
