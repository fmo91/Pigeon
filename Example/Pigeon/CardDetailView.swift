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

struct CardDetailView: View, QueryRenderer {
    @ObservedObject private var card: Query<String, Card>
    
    init(id: String) {
        card = Query<String, Card>(
            key: QueryKey(value: "card_detail_\(id)"),
            behavior: .startImmediately(id),
            fetcher: { id in
                CardDetailRequest(cardId: id)
                    .execute()
                    .map(\.card)
                    .eraseToAnyPublisher()
            }
        )
    }
    
    var body: some View {
       view(for: card.state)
            .navigationBarTitle("Card Detail")
    }
    
    var loadingView: some View {
        Text("Loading...")
    }
    
    func failureView(for failure: Error) -> some View {
        EmptyView()
    }
    
    func successView(for response: Card) -> some View {
        Text(response.name)
    }
}
