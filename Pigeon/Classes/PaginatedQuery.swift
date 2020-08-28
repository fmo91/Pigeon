//
//  PaginatedQuery.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation
import Combine

public final class PaginatedQuery<Request, PageIdentifier: PaginatedQueryKey, Response: Codable>: ObservableObject, QueryCacheListener, QueryInvalidationListener {
    public enum FetchingBehavior {
        case startWhenRequested
        case startImmediately(Request)
    }
    public typealias State = QueryState<Response>
    public typealias QueryFetcher = (Request, PageIdentifier) -> AnyPublisher<Response, Error>
    
    @Published private(set) public var state = State.none
    @Published private(set) public var currentPage: PageIdentifier
    public var valuePublisher: AnyPublisher<Response, Never> {
        $state
            .map { $0.value }
            .filter({ $0 != nil })
            .map { $0! }
            .eraseToAnyPublisher()
    }
    private let key: QueryKey
    private let cache: QueryCacheType
    private let fetcher: QueryFetcher
    private var lastRequest: Request?
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellables = Set<AnyCancellable>()
    
    public init(
        key: QueryKey,
        behavior: FetchingBehavior = .startWhenRequested,
        cache: QueryCacheType = QueryCache.default,
        fetcher: @escaping QueryFetcher
    ) {
        self.key = key
        self.currentPage = PageIdentifier.first
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
                        self.refetchAll(request: lastRequest)
                    }
                case let .newData(newRequest):
                    self.refetchAll(request: newRequest)
                }
            }
            .store(in: &cancellables)
        
        QueryRegistry.shared.register(self, for: key)
    }
    
    private func start(for behavior: FetchingBehavior) {
        switch behavior {
        case .startWhenRequested:
            if let cachedResponse: Response = self.cache.get(for: self.key.appending(currentPage)) {
                state = .succeed(cachedResponse)
            }
            break
        case let .startImmediately(request):
            refetch(request: request, page: currentPage)
        }
    }
    
    public func fetchNextPage() {
        guard let lastRequest = self.lastRequest else {
            return
        }
        
        self.currentPage = self.currentPage.next
        refetch(request: lastRequest, page: self.currentPage)
    }
    
    public func refetchAll(request: Request) {
        currentPage = .first
        refetchCurrent(request: request)
    }
    
    public func refetchCurrent(request: Request) {
        self.refetch(request: request, page: currentPage)
    }
    
    public func refetch(request: Request, page: PageIdentifier) {
        self.lastRequest = request
        self.currentPage = page
        self.cache.invalidate(for: currentPage.asQueryKey)
        NotificationCenter.default.post(
            name: self.currentPage.newDataNotificationName,
            object: nil
        )
        state = .loading
        fetcher(request, page)
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
                    NotificationCenter.default.post(
                        name: self.currentPage.newDataNotificationName,
                        object: response
                    )
                    self.cache.save(response, for: self.currentPage.asQueryKey)
                    self.state = .succeed(response)
                }
            )
            .store(in: &cancellables)
    }
}
