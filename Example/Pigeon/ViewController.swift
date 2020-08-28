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
        QueryCache.setDefault(.userDefaults)
        super.init(rootView: ContentView())
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

//

typealias UsersQuery = Query<Void, [User]>
typealias AlbumsQuery = Query<User, [Album]>

struct ContentView: View {
    @ObservedObject
    private var users = UsersQuery(
        key: .users,
        behavior: .startImmediately(()),
        pollingBehavior: .pollEvery(20),
        fetcher: Fetchers.getUsers
    )
    
    var body: some View {
        NavigationView {
            UsersList()
        }
    }
}

final class UsersViewModel: ObservableObject {
    private var usersQuery = UsersQuery.Consumer(key: .users)
    
    private var cancellables = Set<AnyCancellable>()
    
    var users: [User] {
        usersQuery.state.value ?? []
    }
    
    init() {
        usersQuery.valuePublisher
            .sink { (_) in
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

struct UsersList: View {
    @ObservedObject
    private var viewModel = UsersViewModel()
    
    var body: some View {
        List(viewModel.users) { user in
            NavigationLink(destination: AlbumsList(for: user)) {
                Text(user.name)
            }
        }
        .navigationBarTitle("Users")
    }
}

struct AlbumsList: View {
    let user: User
    
    @ObservedObject
    private var albums: AlbumsQuery
    
    init(for user: User) {
        self.user = user
        
        self.albums = AlbumsQuery(
            key: .albums(for: user),
            behavior: .startImmediately(user),
            fetcher: Fetchers.getAlbums
        )
    }
    
    var body: some View {
        List(albums.state.value ?? []) { album in
            Text(album.title)
        }
        .navigationBarTitle("Albums")
    }
}

//

struct User: Codable, Identifiable {
    let id: Int
    let name: String
}

struct Album: Codable, Identifiable {
    let id: Int
    let title: String
}

extension QueryKey {
    static var users: QueryKey { QueryKey(value: "users") }
    static func albums(for user: User) -> QueryKey {
        QueryKey(value: "albums")
            .appending(user.id.description)
    }
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
    static func getAlbums(request: User) -> AnyPublisher<[Album], Error> {
        URLSession.shared
            .dataTaskPublisher(for: URL(string: "https://jsonplaceholder.typicode.com/users/\(request.id)/albums")!)
            .map(\.data)
            .decode(type: [Album].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
