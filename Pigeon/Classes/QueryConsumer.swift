//
//  QueryConsumer.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation
import Combine

extension Query {
    public final class Consumer: ObservableObject, QueryType {
        private let key: QueryKey
        private let query: AnyQuery<Request, Response>
        public var state: State { query.state }
        public var statePublisher: AnyPublisher<QueryState<Response>, Never> {
            return query.statePublisher
        }
        public var valuePublisher: AnyPublisher<Response, Never> {
            query.statePublisher
                .compactMap { $0.value }
                .eraseToAnyPublisher()
        }
        private var cancellables = Set<AnyCancellable>()
        
        public init(
            key: QueryKey
        ) {
            self.key = key
            self.query = QueryRegistry.shared.resolve(for: key)
            
            query.statePublisher
                .sink { _ in
                    self.objectWillChange.send()
                }
                .store(in: &cancellables)
        }
        
        public func refetch(for parameters: QueryInvalidator.TypedParameters<Request>) {
            QueryInvalidator()
                .invalidateQuery(for: key, with: parameters)
        }
    }
}
