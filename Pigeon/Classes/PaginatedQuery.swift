//
//  PaginatedQuery.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation
import Combine

public final class PaginatedQuery< Request,
                                 PageIdentifier: PaginatedQueryKey,
                                 Response: Codable & Sequence>: ObservableObject, QueryType, QueryInvalidationListener {
    
    public enum FetchingBehavior {
        case startWhenRequested
        case startImmediately(Request)
    }
    public typealias State = QueryState<Response>
    public typealias QueryFetcher = (Request, PageIdentifier) -> AnyPublisher<Response, Error>
    
    @Published public private(set) var items: [Response.Element] = []
    @Published private var internalState = State.idle
    @Published public private(set) var currentPage: PageIdentifier
    private var internalValuePublisher: AnyPublisher<Response, Never> {
        $internalState
            .compactMap { $0.value }
            .eraseToAnyPublisher()
    }
    public var valuePublisher: AnyPublisher<Response, Never> {
        statePublisher
            .compactMap { $0.value }
            .eraseToAnyPublisher()
    }
    public var state: QueryState<Response> {
        switch internalState {
        case .idle:
            return .idle
        case .loading:
            return .loading
        case let .failed(error):
            return .failed(error)
        case .succeed:
            if let items = items as? Response {
                return .succeed(items)
            } else {
                return .failed(ItemError.castFail)
            }
        }
    }
    public var statePublisher: AnyPublisher<QueryState<Response>, Never> {
        $internalState
            .map { _ -> QueryState<Response> in
                return self.state
            }
            .eraseToAnyPublisher()
    }
    private let key: QueryKey
    private let keyAdapter: (QueryKey, Request) -> QueryKey
    private let cache: QueryCacheType
    private let cacheConfig: QueryCacheConfig
    private let fetcher: QueryFetcher
    private var lastRequest: Request?
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellables = Set<AnyCancellable>()
    
    public init(
        key: QueryKey,
        firstPage: PageIdentifier,
        keyAdapter: @escaping (QueryKey, Request) -> QueryKey = { key, _ in key },
        behavior: FetchingBehavior = .startWhenRequested,
        cache: QueryCacheType = QueryCache.global,
        cacheConfig: QueryCacheConfig = .global,
        fetcher: @escaping QueryFetcher
    ) {
        self.key = key
        self.currentPage = firstPage
        self.keyAdapter = keyAdapter
        self.cache = cache
        self.cacheConfig = cacheConfig
        self.fetcher = fetcher
        
        start(for: behavior)
        
        internalValuePublisher
            .sink { (items) in
                self.items.append(contentsOf: items)
            }
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
        
        QueryRegistry.shared.register(self.eraseToAnyQuery(), for: key)
    }
    
    private func start(for behavior: FetchingBehavior) {
        switch behavior {
        case .startWhenRequested:
            if cacheConfig.usagePolicy == .useInsteadOfFetching
                || cacheConfig.usagePolicy == .useAndThenFetch {
                if let cachedResponse: Response = self.getCacheValueIfPossible(for: self.key) {
                    internalState = .succeed(cachedResponse)
                }
            }
        case let .startImmediately(request):
            refetchPage(request: request, page: currentPage)
        }
    }
    
    private func isCacheValid(for key: QueryKey) -> Bool {
        return self.cache.isValueValid(
            forKey: key.appending(currentPage),
            timestamp: Date(),
            andInvalidationPolicy: self.cacheConfig.invalidationPolicy
        )
    }
    
    private func getCacheValueIfPossible(for key: QueryKey) -> Response? {
        if isCacheValid(for: key) {
           return self.cache.get(for: key.appending(currentPage))
        } else {
            return nil
        }
    }
    
    public func fetchNextPage() {
        guard let lastRequest = self.lastRequest else {
            return
        }
        
        self.currentPage = self.currentPage.next
        refetchPage(request: lastRequest, page: self.currentPage)
    }
    
    public func refetch(request: Request) {
        items = []
        currentPage = currentPage.first
        refetchCurrent(request: request)
    }
    
    private func refetchCurrent(request: Request) {
        self.refetchPage(request: request, page: currentPage)
    }
    
    private func refetchPage(request: Request, page: PageIdentifier) {
        let key = self.keyAdapter(self.key, request)
        
        self.lastRequest = request
        self.currentPage = page
        
        if self.cacheConfig.usagePolicy == .useInsteadOfFetching && isCacheValid(for: key) {
            if let value: Response = self.cache.get(for: key) {
                self.internalState = .succeed(value)
            }
            return
        }
        
        if self.cacheConfig.usagePolicy == .useAndThenFetch {
            if let value = getCacheValueIfPossible(for: key) {
                self.internalState = .succeed(value)
            }
        }
        
        if self.cacheConfig.usagePolicy == .useIfFetchFails {
            internalState = .loading
        }
        
        fetcher(request, page)
            .sink(
                receiveCompletion: { (completion: Subscribers.Completion<Error>) in
                    switch completion {
                    case let .failure(error):
                        self.timerCancellables.forEach({ $0.cancel() })
                        if self.cacheConfig.usagePolicy == .useIfFetchFails {
                            if let value = self.getCacheValueIfPossible(for: key) {
                                self.internalState = .succeed(value)
                            } else {
                                self.internalState = .failed(error)
                            }
                        } else {
                            self.internalState = .failed(error)
                        }
                    case .finished:
                        break
                    }
                },
                receiveValue: { (response: Response) in
                    self.internalState = .succeed(response)
                    self.cache.save(response, for: key.appending(self.currentPage), andTimestamp: Date())
                }
            )
            .store(in: &cancellables)
    }
}

enum ItemError: Error {
    case castFail
}
