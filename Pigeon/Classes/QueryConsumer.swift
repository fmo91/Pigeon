//
//  QueryConsumer.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation
import Combine

public final class QueryConsumer<Response: Codable>: ObservableObject, QueryCacheListener {
    public typealias State = QueryState<Response>
    @Published public var state = State.none
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        key: QueryKey,
        cache: QueryCacheType = QueryCache.default
    ) {
        if let cachedResponse: Response = cache.get(for: key) {
            state = .succeed(cachedResponse)
        }
        listenQueryCache(for: key)
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
    }
}
