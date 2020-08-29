//
//  PaginatedQuery.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation
import Combine

public final class PaginatedQuery<Request, PageIdentifier: PaginatedQueryKey, Response: Codable & Sequence>: ObservableObject, QueryType, QueryInvalidationListener {
    public enum FetchingBehavior {
        case startWhenRequested
        case startImmediately(Request)
    }
    public typealias State = QueryState<Response>
    public typealias QueryFetcher = (Request, PageIdentifier) -> AnyPublisher<Response, Error>
    
    @Published private(set) public var items: [Response.Element] = []
    @Published private var internalState = State.idle
    @Published private(set) public var currentPage: PageIdentifier
    private var internalValuePublisher: AnyPublisher<Response, Never> {
        $internalState
            .map { $0.value }
            .filter({ $0 != nil })
            .map { $0! }
            .eraseToAnyPublisher()
    }
    public var valuePublisher: AnyPublisher<Response, Never> {
        statePublisher
            .map { $0.value }
            .filter({ $0 != nil })
            .map { $0! }
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
            return .succeed(items as! Response)
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
    private let cache: QueryCacheType
    private let cacheConfig: QueryCacheConfig
    private let fetcher: QueryFetcher
    private var lastRequest: Request?
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellables = Set<AnyCancellable>()
    
    public init(
        key: QueryKey,
        behavior: FetchingBehavior = .startWhenRequested,
        cache: QueryCacheType = QueryCache.global,
        cacheConfig: QueryCacheConfig = .global,
        fetcher: @escaping QueryFetcher
    ) {
        self.key = key
        self.currentPage = PageIdentifier.first
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
            if cacheConfig.usagePolicy == .useInsteadOfFetching
                || cacheConfig.usagePolicy == .useAndThenFetch {
                if let cachedResponse: Response = self.getCacheValueIfPossible() {
                    internalState = .succeed(cachedResponse)
                }
            }
            break
        case let .startImmediately(request):
            refetch(request: request, page: currentPage)
        }
    }
    
    private var isCacheValid: Bool {
        return self.cache.isValueValid(
            forKey: self.key,
            timestamp: Date(),
            andInvalidationPolicy: self.cacheConfig.invalidationPolicy
        )
    }
    
    private func getCacheValueIfPossible() -> Response? {
        if isCacheValid {
           return self.cache.get(for: self.key.appending(currentPage))
        } else {
            return nil
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
        items = []
        currentPage = .first
        refetchCurrent(request: request)
    }
    
    private func refetchCurrent(request: Request) {
        self.refetch(request: request, page: currentPage)
    }
    
    private func refetch(request: Request, page: PageIdentifier) {
        self.lastRequest = request
        self.currentPage = page
        
        if self.cacheConfig.usagePolicy == .useInsteadOfFetching && isCacheValid {
            if let value: Response = self.cache.get(for: self.key) {
                self.internalState = .succeed(value)
            }
            return
        }
        
        if self.cacheConfig.usagePolicy == .useAndThenFetch {
            if let value = getCacheValueIfPossible() {
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
                            if let value = self.getCacheValueIfPossible() {
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
                    self.cache.save(response, for: self.key.appending(self.currentPage), andTimestamp: Date())
                }
            )
            .store(in: &cancellables)
    }
}
