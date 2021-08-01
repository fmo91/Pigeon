//
//  QueryCacheConfig.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 28/08/2020.
//

import Foundation

public struct QueryCacheConfig {
    public enum InvalidationPolicy {
        case notExpires
        case expiresAfter(TimeInterval)
    }
    public enum UsagePolicy {
        case useInsteadOfFetching
        case useIfFetchFails
        case useAndThenFetch
    }
    
    let invalidationPolicy: InvalidationPolicy
    let usagePolicy: UsagePolicy
    
    public init(
        invalidationPolicy: InvalidationPolicy = .notExpires,
        usagePolicy: UsagePolicy = .useIfFetchFails
    ) {
        self.invalidationPolicy = invalidationPolicy
        self.usagePolicy = usagePolicy
    }
    
    public private(set) static var global: QueryCacheConfig = .init()
    public static func setGlobal(_ config: QueryCacheConfig) {
        QueryCacheConfig.global = config
    }
}
