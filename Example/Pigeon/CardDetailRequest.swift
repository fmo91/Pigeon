//
//  CardDetailRequest.swift
//  Pigeon_Example
//
//  Created by Fernando Martín Ortiz on 27/08/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation

struct CardDetailRequest: RequestType {
    typealias ResponseType = CardDetailResponse
    
    let cardId: String
    
    var data: RequestData {
        RequestData(
            path: "https://api.magicthegathering.io/v1/cards/\(cardId)",
            method: .get,
            params: nil,
            headers: nil
        )
    }
}
