//
//  ViewController.swift
//  Pigeon
//
//  Created by fmo91 on 08/23/2020.
//  Copyright (c) 2020 fmo91. All rights reserved.
//

import UIKit
import Pigeon
import Combine

struct User: Codable {
    let id: Int
    let name: String
}

extension QueryKey {
    static var users: QueryKey { QueryKey(value: "users") }
}

class ViewController: UIViewController {
    
    private var cancellables = Set<AnyCancellable>()
    
    var users = Pigeon.Query<Void, [User]>(
        key: .users,
        behavior: .startImmediately(()),
        pollingBehavior: .pollEvery(2),
        fetcher: {
            URLSession.shared
                .dataTaskPublisher(for: URL(string: "https://jsonplaceholder.typicode.com/users")!)
                .map(\.data)
                .decode(type: [User].self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        
        users.$state.sink { (state: QueryState<[User]>) in
            switch state {
            case let .failed(error):
                print("Oops! \(error)")
            case .loading:
                print("It is loading")
            case .none:
                print("This just starts...")
            case let .succeed(users):
                print(users)
            }
        }.store(in: &cancellables)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

