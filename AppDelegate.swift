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

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    let rootViewController = RootViewController()

    let window = UIWindow(frame: UIScreen.mainScreen().bounds)
    window.rootViewController = rootViewController
    self.window = window

    window.makeKeyAndVisible()

    return true
  }


}

