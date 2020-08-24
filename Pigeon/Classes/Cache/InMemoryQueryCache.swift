//
//  InMemoryQueryCache.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation

public final class InMemoryQueryCache: QueryCacheType {
    private var cache: [QueryKey: Any?] = [:]
    
    public static let shared = InMemoryQueryCache()
    private init() {}
    
    public func save<T: Codable>(_ value: T, for key: QueryKey) {
        cache[key] = value
    }
    
    public func invalidate(for key: QueryKey) {
        cache[key] = nil
    }
    
    public func get<T: Codable>(for key: QueryKey) -> T? {
        return cache[key] as? T
    }
}
