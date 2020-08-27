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
    public final class Consumer: ObservableObject, QueryCacheListener {
        public typealias State = QueryState<Response>
        private let key: QueryKey
        private let query: Query<Request, Response>
        public var state: State { query.state }
        public var statePublisher: Published<State>.Publisher {
            return query.$state
        }
        public var valuePublisher: AnyPublisher<Response, Never> {
            query.$state
                .map { $0.value }
                .filter({ $0 != nil })
                .map { $0! }
                .eraseToAnyPublisher()
        }
        private var cancellables = Set<AnyCancellable>()
        
        public init(
            key: QueryKey
        ) {
            self.key = key
            self.query = QueryRegistry.shared.resolve(for: key)
            
            query.$state
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
