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
        behavior: .startImmediately(()),
        cacheConfig: QueryCacheConfig(
            invalidationPolicy: .expiresAfter(1000),
            usagePolicy: .useInsteadOfFetching
        ),
        fetcher: { request, page in
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
