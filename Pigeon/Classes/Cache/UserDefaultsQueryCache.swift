//
//  UserDefaultsQueryCache.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation

public final class UserDefaultsQueryCache: QueryCacheType {
    public static let shared = UserDefaultsQueryCache()
    private init() {}
    
    public func save<T: Codable>(_ value: T, for key: QueryKey, andTimestamp timestamp: Date) {
        guard let data = try? JSONEncoder().encode(value) else {
            return
        }
        UserDefaults.standard.set(data, forKey: key.queryKeyValue)
        UserDefaults.standard.set(timestamp.timeIntervalSince1970, forKey: key.queryKeyValue.appending("_:::::time"))
        UserDefaults.standard.synchronize()
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
            let itemTimestamp: TimeInterval = getTimestamp(for: key.appending(":::::time"))
            let comparisonTimestamp = timestamp.timeIntervalSince1970
            
            if itemTimestamp + additionalTimestamp > comparisonTimestamp {
                return true
            } else {
                return false
            }
        }
    }
    
    public func invalidate(for key: QueryKey) {
        UserDefaults.standard.removeObject(forKey: key.queryKeyValue)
    }
    
    private func getTimestamp(for key: QueryKey) -> Double {
        return UserDefaults.standard.double(forKey: key.queryKeyValue)
    }
    
    public func get<T: Codable>(for key: QueryKey) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key.queryKeyValue) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
