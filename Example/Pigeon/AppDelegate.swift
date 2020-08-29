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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let paginatedQuery = PaginatedQuery<Int, NumericPaginatedQueryKey, [String]>(
            key: QueryKey(value: "sample_1"),
            fetcher: { number, page in
                Just(["Funca? Number: \(number) ::: Page: \(page.current)"])
                    .tryMap { $0 }
                    .eraseToAnyPublisher()
            }
        )
        
        let w = paginatedQuery.$items.sink { (state: [String]) in
            print(state)
        }
        
        paginatedQuery.refetchAll(request: 10)
        
        paginatedQuery.fetchNextPage()
        paginatedQuery.fetchNextPage()
        paginatedQuery.fetchNextPage()
        
        let controller = ViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = controller
        window!.makeKeyAndVisible()
        
        return true
    }
}

