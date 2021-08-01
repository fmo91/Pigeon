//
//  QueryRegistry.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 26/08/2020.
//

import Foundation
import Combine

final class QueryRegistry {
    private var queries: [QueryKey: Any] = [:]
    
    static let shared: QueryRegistry = QueryRegistry()
    private init() {}
    
    func register<Request, Response>(
        _ query: AnyQuery<Request, Response>,
        for key: QueryKey
    ) {
        queries[key] = query
    }
    
    func unregister(for key: QueryKey) {
        queries.removeValue(forKey: key)
    }
    
    func resolve<Request, Response>(for key: QueryKey) -> AnyQuery<Request, Response> {
        //let queries: AnyQuery<Request, Response>
        if let queries = queries[key] as? AnyQuery<Request, Response> {
            return queries
        }
        //todo fix stateGetter context
        return AnyQuery<Request, Response>(stateGetter: { QueryState.loading },
                                           statePublisherGetter: {
                                            AnyPublisher<QueryState<Response>, Never>(
                                                Empty<QueryState<Response>, Never>())
                                           })
    }
}
