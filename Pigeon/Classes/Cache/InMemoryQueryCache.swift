//
//  InMemoryQueryCache.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation

public final class InMemoryQueryCache: QueryCacheType {
    private var cache: [QueryKey: (timestamp: Date, value: Any?)] = [:]
    
    public static let shared = InMemoryQueryCache()
    private init() {}
    
    public func save<T: Codable>(_ value: T, for key: QueryKey, andTimestamp timestamp: Date) {
        cache[key] = (timestamp: timestamp, value: value)
    }
    
    public func invalidate(for key: QueryKey) {
        cache[key] = nil
    }
    
    public func isValueValid(
        forKey key: QueryKey,
        timestamp: Date,
        andInvalidationPolicy invalidationPolicy: QueryCacheConfig.InvalidationPolicy
    ) -> Bool {
        switch invalidationPolicy {
        case .notExpires:
            return true
        case let .expiresAfter(additionalTimestamp):
            let item = cache[key]
            let comparisonDate = Calendar.current.date(
                byAdding: .second,
                value: Int(additionalTimestamp),
                to: timestamp
            )
            guard let itemTimestamp = item?.timestamp else {
                return false
            }
            if comparisonDate?.compare(itemTimestamp) == ComparisonResult.orderedDescending {
                return true
            } else {
                return false
            }
        }
    }
    
    public func get<T: Codable>(for key: QueryKey) -> T? {
        return cache[key]?.value as? T
    }
}
