//
//  QueryType.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 29/08/2020.
//

import Foundation
import Combine

public protocol QueryType {
    associatedtype Request
    associatedtype Response
 
    var state: QueryState<Response> { get }
    var statePublisher: AnyPublisher<QueryState<Response>, Never> { get }
}

public extension QueryType {
    func eraseToAnyQuery() -> AnyQuery<Request, Response> {
        return AnyQuery<Request, Response>(
            stateGetter: { self.state },
            statePublisherGetter: { self.statePublisher }
        )
    }
}
