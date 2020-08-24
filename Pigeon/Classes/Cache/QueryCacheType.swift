//
//  QueryCacheType.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation

public protocol QueryCacheType {
    func save<T: Codable>(_ value: T, for key: QueryKey)
    func invalidate(for key: QueryKey)
    func get<T: Codable>(for key: QueryKey) -> T?
}

public struct QueryCache {
    private let wrappedCache: QueryCacheType
    
    public init(wrappedCache: QueryCacheType) {
        self.wrappedCache = wrappedCache
    }
    
    private(set) public static var `default`: QueryCacheType = inMemory.wrappedCache
    public static func setDefault(_ wrapper: QueryCache) {
        QueryCache.default = wrapper.wrappedCache
    }
    
    public static var inMemory: QueryCache { .init(wrappedCache: InMemoryQueryCache.shared) }
    public static var userDefaults: QueryCache { .init(wrappedCache: UserDefaultsQueryCache.shared) }
}
