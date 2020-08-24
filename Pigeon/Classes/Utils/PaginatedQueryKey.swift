//
//  PaginatedQueryKey.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation

public protocol PaginatedQueryKey: QueryKeyType {
    static var first: Self { get }
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
    
    public static var first: NumericPaginatedQueryKey {
        NumericPaginatedQueryKey(current: 0)
    }
    
    public var next: NumericPaginatedQueryKey {
        NumericPaginatedQueryKey(current: current + 1)
    }
}
