//
//  RequestType.swift
//  Pigeon_Example
//
//  Created by Fernando Martín Ortiz on 27/08/2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import Combine

public enum ConnError: Swift.Error {
    case invalidURL
    case noData
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

public struct RequestData {
    public let path: String
    public let method: HTTPMethod
    public let params: [String: Any?]?
    public let headers: [String: String]?
    
    public init (
        path: String,
        method: HTTPMethod = .get,
        params: [String: Any?]? = nil,
        headers: [String: String]? = nil
    ) {
        self.path = path
        self.method = method
        self.params = params
        self.headers = headers
    }
}

public protocol RequestType {
    associatedtype ResponseType: Codable
    var data: RequestData { get }
}

public extension RequestType {
    func execute (
        dispatcher: NetworkDispatcher = URLSessionNetworkDispatcher.instance
    ) -> AnyPublisher<ResponseType, Error> {
        return dispatcher.dispatch(request: self.data)
            .decode(type: ResponseType.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

public protocol NetworkDispatcher {
    func dispatch(request: RequestData) -> AnyPublisher<Data, Error>
}

public struct URLSessionNetworkDispatcher: NetworkDispatcher {
    public static let instance = URLSessionNetworkDispatcher()
    private init() {}
    
    public func dispatch(request: RequestData) -> AnyPublisher<Data, Error> {
        guard let url = URL(string: request.path) else {
            return Fail(outputType: Data.self, failure: ConnError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        do {
            if let params = request.params {
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            }
        } catch let error {
            return Fail(outputType: Data.self, failure: error)
                .eraseToAnyPublisher()
        }
        
        if let headers = request.headers {
            urlRequest.allHTTPHeaderFields = headers
        }
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .map(\.data)
            .mapError({ $0 })
            .eraseToAnyPublisher()
    }
}
