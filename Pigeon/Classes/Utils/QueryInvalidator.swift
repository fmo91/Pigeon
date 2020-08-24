//
//  QueryInvalidator.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation

public struct QueryInvalidator {
    public func invalidateQuery(for key: QueryKey, with request: Any?) {
        NotificationCenter.default.post(
            name: key.invalidationNotificationName,
            object: request
        )
    }
}
