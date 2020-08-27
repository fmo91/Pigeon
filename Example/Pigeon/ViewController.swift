//
//  ViewController.swift
//  Pigeon
//
//  Created by fmo91 on 08/23/2020.
//  Copyright (c) 2020 fmo91. All rights reserved.
//

import UIKit
import Pigeon
import SwiftUI
import Combine

class ViewController: UIHostingController<ContentView> {
    
    init() {
        super.init(rootView: ContentView())
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

//

typealias UsersQuery = Query<Void, [User]>

struct ContentView: View {
    @ObservedObject
    private var users = UsersQuery(
        key: .users,
        behavior: .startImmediately(()),
        fetcher: Fetchers.getUsers
    )
    
    var body: some View {
        UsersList()
    }
}

struct UsersList: View {
    @ObservedObject
    private var users = UsersQuery.Consumer(key: .users)
    
    var body: some View {
        List(users.state.value ?? []) { user in
            Text(user.name)
        }
    }
}

//

struct User: Codable, Identifiable {
    let id: Int
    let name: String
}

extension QueryKey {
    static var users: QueryKey { QueryKey(value: "users") }
}

enum Fetchers {
    static func getUsers(request: Void) -> AnyPublisher<[User], Error> {
        URLSession.shared
            .dataTaskPublisher(for: URL(string: "https://jsonplaceholder.typicode.com/users")!)
            .map(\.data)
            .decode(type: [User].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
