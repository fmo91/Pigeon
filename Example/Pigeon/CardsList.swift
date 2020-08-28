//
//  CardsList.swift
//  Pigeon_Example
//
//  Created by Fernando Martín Ortiz on 27/08/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import SwiftUI
import Pigeon

struct CardsList: View {
    @ObservedObject private var cards = Query<Void, [Card]>(
        key: QueryKey(value: "cards"),
        behavior: .startImmediately(()),
        fetcher: {
            GetCardsRequest()
                .execute()
                .map(\.cards)
                .eraseToAnyPublisher()
        }
    )
    
    var body: some View {
        content
            .navigationBarTitle("Cards")
    }
    
    var content: some View {
        switch cards.state {
        case .none, .loading:
            return AnyView(Text("Loading"))
        case .failed:
            return AnyView(Text("It failed"))
        case let .succeed(cards):
            return AnyView (
                List(cards) { card in
                    NavigationLink(destination: CardDetailView(id: card.id)) {
                        Text(card.name)
                    }
                }
            )
        }
    }
}
