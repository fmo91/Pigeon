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
    @ObservedObject private var cards = Query<Void, [Card]>.Consumer(key: QueryKey(value: "cards"))
    
    let renderer = CardsListRenderer()
    
    var body: some View {
        renderer.view(for: cards.state)
            .navigationBarTitle("Cards")
    }
}

// MARK: - QueryRenderer -
struct CardsListRenderer: QueryRenderer {
    var loadingView: some View {
        Text("Loading...")
    }
    
    func failureView(for failure: Error) -> some View {
        Text("Failed!")
    }
    
    func successView(for response: [Card]) -> some View {
        List(response) { card in
            NavigationLink(destination: CardDetailView(id: card.id)) {
                Text(card.name)
            }
        }
    }
}
