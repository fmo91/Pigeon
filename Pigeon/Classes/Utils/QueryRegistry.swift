//
//  QueryRegistry.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 26/08/2020.
//

import Foundation

final class QueryRegistry {
    private var queries: [QueryKey: Any] = [:]
    
    static let shared: QueryRegistry = QueryRegistry()
    private init() {}
    
    func register<Request, Response>(_ query: Query<Request, Response>, for key: QueryKey) {
        queries[key] = query
    }
    
    func unregister(for key: QueryKey) {
        queries.removeValue(forKey: key)
    }
    
    func resolve<Request, Response>(for key: QueryKey) -> Query<Request, Response> {
        return queries[key] as! Query<Request, Response>
    }
}
