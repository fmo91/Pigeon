//
//  QueryInvalidationListener.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation
import Combine

public protocol QueryInvalidationListener {
    associatedtype Request
}

public extension QueryInvalidationListener {
    func listenQueryInvalidation(for key: QueryKey) -> AnyPublisher<Request, Never> {
        NotificationCenter.default.publisher(for: key.invalidationNotificationName)
            .map(\.object)
            .filter { $0 is Request }
            .map { $0 as! Request }
            .eraseToAnyPublisher()
    }
}
