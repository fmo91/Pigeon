//
//  Query.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation
import Combine

public final class Query<Request, Response: Codable>: ObservableObject, QueryCacheListener, QueryInvalidationListener {
    public enum FetchingBehavior {
        case startWhenRequested
        case startImmediately(Request)
    }
    public typealias State = QueryState<Response>
    public typealias QueryFetcher = (Request) -> AnyPublisher<Response, Error>
    
    @Published public var state = State.none
    private let key: QueryKey
    private let cache: QueryCacheType
    private let fetcher: QueryFetcher
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        key: QueryKey,
        behavior: FetchingBehavior = .startWhenRequested,
        cache: QueryCacheType = QueryCache.default,
        fetcher: @escaping QueryFetcher
    ) {
        self.key = key
        self.cache = cache
        self.fetcher = fetcher
        
        start(for: behavior)
        
        listenQueryCache(for: key)
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
        
        listenQueryInvalidation(for: key)
            .sink { (request: Request) in
                self.refetch(request: request)
            }
            .store(in: &cancellables)
    }
    
    private func start(for behavior: FetchingBehavior) {
        switch behavior {
        case .startWhenRequested:
            if let cachedResponse: Response = self.cache.get(for: key) {
                state = .succeed(cachedResponse)
            }
            break
        case let .startImmediately(request):
            refetch(request: request)
        }
    }
    
    public func refetch(request: Request) {
        self.cache.invalidate(for: key)
        NotificationCenter.default.post(
            name: self.key.notificationName,
            object: nil
        )
        state = .loading
        fetcher(request)
            .sink(
                receiveCompletion: { (completion: Subscribers.Completion<Error>) in
                    switch completion {
                    case let .failure(error):
                        self.state = .failed(error)
                    case .finished:
                        break
                    }
                },
                receiveValue: { (response: Response) in
                    self.cache.save(response, for: self.key)
                    NotificationCenter.default.post(
                        name: self.key.notificationName,
                        object: response
                    )
                }
            )
            .store(in: &cancellables)
    }
}
