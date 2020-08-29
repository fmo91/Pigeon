//
//  PaginatedQueryKey.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation

public protocol PaginatedQueryKey: QueryKeyType {
    var first: Self { get }
    var next: Self { get }
}

public extension PaginatedQueryKey {
    var asQueryKey: QueryKey {
        QueryKey(value: queryKeyValue)
    }
}

public struct NumericPaginatedQueryKey: PaginatedQueryKey {
    public let current: Int
    
    public var queryKeyValue: String {
        current.description
    }
    
    public var first: NumericPaginatedQueryKey {
        NumericPaginatedQueryKey(current: 0)
    }
    
    public var next: NumericPaginatedQueryKey {
        NumericPaginatedQueryKey(current: current + 1)
    }
    
    public init(current: Int) {
        self.current = current
    }
}

public struct LimitOffsetPaginatedQueryKey: PaginatedQueryKey {
    public let limit: Int
    public let offset: Int
    
    public var queryKeyValue: String {
        "\(limit)_\(offset)"
    }
    
    public var first: Self {
        return LimitOffsetPaginatedQueryKey(
            limit: limit,
            offset: 0
        )
    }
    
    public var next: Self {
        return LimitOffsetPaginatedQueryKey(
            limit: limit,
            offset: offset + limit
        )
    }
    
    public init(limit: Int, offset: Int) {
        self.limit = limit
        self.offset = offset
    }
}
