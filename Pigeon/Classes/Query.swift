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
    public enum PollingBehavior {
        case noPolling
        case pollEvery(TimeInterval)
    }
    public typealias State = QueryState<Response>
    public typealias QueryFetcher = (Request) -> AnyPublisher<Response, Error>
    
    @Published public var state = State.none
    public var valuePublisher: AnyPublisher<Response, Never> {
        $state
            .map { $0.value }
            .filter({ $0 != nil })
            .map { $0! }
            .eraseToAnyPublisher()
    }
    private let key: QueryKey
    private let pollingBehavior: PollingBehavior
    private let cache: QueryCacheType
    private let fetcher: QueryFetcher
    private var lastRequest: Request?
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellables = Set<AnyCancellable>()
    
    public init(
        key: QueryKey,
        behavior: FetchingBehavior = .startWhenRequested,
        pollingBehavior: PollingBehavior = .noPolling,
        cache: QueryCacheType = QueryCache.default,
        fetcher: @escaping QueryFetcher
    ) {
        self.key = key
        self.pollingBehavior = pollingBehavior
        self.cache = cache
        self.fetcher = fetcher
        
        start(for: behavior)
        
        listenQueryCache(for: key)
            .assign(to: \.state, on: self)
            .store(in: &cancellables)
        
        listenQueryInvalidation(for: key)
            .sink { (parameters: QueryInvalidator.TypedParameters<Request>) in
                switch parameters {
                case .lastData:
                    if let lastRequest = self.lastRequest {
                        self.refetch(request: lastRequest)
                    }
                case let .newData(newRequest):
                    self.refetch(request: newRequest)
                }
            }
            .store(in: &cancellables)
        
        QueryRegistry.shared.register(self, for: key)
    }
    
    deinit {
        QueryRegistry.shared.unregister(for: key)
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
        lastRequest = request
        timerCancellables.forEach({ $0.cancel() })
        cache.invalidate(for: key)
        NotificationCenter.default.post(
            name: self.key.newDataNotificationName,
            object: nil
        )
        state = .loading

        performFetch(for: request)
        startPollingIfNeeded(for: request)
    }
    
    private func startPollingIfNeeded(for request: Request) {
        switch pollingBehavior {
        case .noPolling:
            break
        case let .pollEvery(interval):
            Timer
                .publish(every: interval, on: .main, in: .defaultRunLoopMode)
                .autoconnect()
                .sink { (_) in
                    self.performFetch(for: request)
                }
                .store(in: &timerCancellables)
        }
    }
    
    private func performFetch(for request: Request) {
        fetcher(request)
            .sink(
                receiveCompletion: { (completion: Subscribers.Completion<Error>) in
                    switch completion {
                    case let .failure(error):
                        self.timerCancellables.forEach({ $0.cancel() })
                        self.state = .failed(error)
                    case .finished:
                        break
                    }
                },
                receiveValue: { (response: Response) in
                    self.cache.save(response, for: self.key)
                    NotificationCenter.default.post(
                        name: self.key.newDataNotificationName,
                        object: response
                    )
                }
            )
            .store(in: &cancellables)
    }
}
