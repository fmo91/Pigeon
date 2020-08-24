//
//  QueryKey.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation

public protocol QueryKeyType {
    var queryKeyValue: String { get }
}

public struct QueryKey: Hashable, QueryKeyType {
    public let queryKeyValue: String
    
    public init(value: String) {
        self.queryKeyValue = value
    }
    
    public func appending(_ suffix: String) -> QueryKey {
        return QueryKey(value: "\(queryKeyValue)_\(suffix)")
    }
    
    public func appending(_ key: QueryKeyType) -> QueryKey {
        return appending(key.queryKeyValue)
    }
}

public extension QueryKeyType {
    var notificationName: Notification.Name {
        Notification.Name("\(queryKeyValue)_notification")
    }
    var invalidationNotificationName: Notification.Name {
        Notification.Name("\(queryKeyValue)_notification_invalidation")
    }
}
