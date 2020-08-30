//
//  CardDetailView.swift
//  Pigeon_Example
//
//  Created by Fernando Martín Ortiz on 27/08/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import Pigeon

struct CardDetailView: View {
    @ObservedObject private var card = Query<String, Card>(
        key: QueryKey(value: "card_detail"),
        keyAdapter: { key, id in
            key.appending(id)
        },
        cache: UserDefaultsQueryCache.shared,
        cacheConfig: QueryCacheConfig(
            invalidationPolicy: .expiresAfter(500),
            usagePolicy: .useInsteadOfFetching
        ),
        fetcher: { id in
            CardDetailRequest(cardId: id)
                .execute()
                .map(\.card)
                .eraseToAnyPublisher()
        }
    )
    private let id: String
    
    let renderer = NameRepresentableRenderer<Card>()
    
    init(id: String) {
        self.id = id
    }
    
    var body: some View {
        renderer.view(for: card.state)
            .navigationBarTitle("Card Detail")
    }
}

protocol NameRepresentable {
    var name: String { get }
}

extension Card: NameRepresentable {}

struct NameRepresentableRenderer<T: NameRepresentable>: QueryRenderer {
    var loadingView: some View {
        Text("Loading...")
    }
    
    func failureView(for failure: Error) -> some View {
        EmptyView()
    }
    
    func successView(for response: T) -> some View {
        Text(response.name)
    }
}
