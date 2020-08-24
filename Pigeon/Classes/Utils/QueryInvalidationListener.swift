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
    func listenQueryInvalidation(for key: QueryKey) -> AnyPublisher<QueryInvalidator.TypedParameters<Request>, Never> {
        NotificationCenter.default.publisher(for: key.invalidationNotificationName)
            .map(\.object)
            .map { ($0 as? QueryInvalidator.Parameters)?
                .toTypedParameters(of: Request.self) }
            .filter({ $0 != nil })
            .map { $0! }
            .eraseToAnyPublisher()
    }
}
