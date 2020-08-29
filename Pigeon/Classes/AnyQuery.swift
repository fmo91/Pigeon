//
//  AnyQuery.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 29/08/2020.
//

import Foundation
import Combine

/// Type erased QueryType
/// this type encapsulates the state accessors for an underlying concrete query.
public final class AnyQuery<Request, Response>: QueryType {
    private let stateGetter: () -> QueryState<Response>
    private let statePublisherGetter: () -> AnyPublisher<QueryState<Response>, Never>
    
    /// A  state that encapsulates the response type
    public var state: QueryState<Response> {
        return stateGetter()
    }
    
    /// A publisher for the internal state value
    public var statePublisher: AnyPublisher<QueryState<Response>, Never> {
        return statePublisherGetter()
    }
    
    public init(
        stateGetter: @escaping () -> QueryState<Response>,
        statePublisherGetter: @escaping () -> AnyPublisher<QueryState<Response>, Never>
    ) {
        self.stateGetter = stateGetter
        self.statePublisherGetter = statePublisherGetter
    }
}
