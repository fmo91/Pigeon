//
//  AppDelegate.swift
//  Pigeon
//
//  Created by fmo91 on 08/23/2020.
//  Copyright (c) 2020 fmo91. All rights reserved.
//

import UIKit
import Combine
import Pigeon

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let controller = ViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        if let window = window {
            window.rootViewController = controller
            window.makeKeyAndVisible()
        }
        return true
    }
}
