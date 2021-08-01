//
//  ContentView.swift
//  Pigeon_Example
//
//  Created by Fernando Martín Ortiz on 27/08/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import SwiftUI
import Pigeon
import Combine

struct ContentView: View {
    @ObservedObject private var cards = PaginatedQuery<Void, NumericPaginatedQueryKey, [Card]>(
        key: QueryKey(value: "cards"),
        firstPage: NumericPaginatedQueryKey(current: 0),
        behavior: .startImmediately(()),
        cacheConfig: QueryCacheConfig(
            invalidationPolicy: .expiresAfter(1000),
            usagePolicy: .useInsteadOfFetching
        ),
        fetcher: { _, page in
            print("Fetching page no. \(page)")
            return GetCardsRequest()
                .execute()
                .map(\.cards)
                .eraseToAnyPublisher()
        }
    )
    
    var body: some View {
        NavigationView {
            CardsList()
        }
    }
}

struct UsersList: View {
    @ObservedObject private var users = Query<Int, [User]>(
        key: QueryKey(value: "users"),
        keyAdapter: { key, id in
            key.appending(id.description)
        },
        behavior: .startImmediately(1),
        cache: UserDefaultsQueryCache.shared,
        fetcher: { _ in
            let url = URL(string: "https://jsonplaceholder.typicode.com/users/")
            if let url = url {
                return URLSession.shared
                    .dataTaskPublisher(for: url)
                    .map(\.data)
                    .decode(type: [User].self, decoder: JSONDecoder())
                    .receive(on: DispatchQueue.main)
                    .eraseToAnyPublisher()
            } else {
                return AnyPublisher<[User], Error>(Empty<[User], Error>())
            }
        }
    )
    
    var body: some View {
        self.view(for: users.state)
    }
}

extension UsersList: QueryRenderer {
    var loadingView: some View {
        Text("Loading...")
    }
    
    func successView(for response: [User]) -> some View {
        List(response) { user in
            Text(user.name)
        }
    }
    
    func failureView(for failure: Error) -> some View {
        Text("It failed...")
    }
}

struct User: Codable, Identifiable {
    let id: Int
    let name: String
}
