//
//  QueryRenderer.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 27/08/2020.
//

import Foundation
import SwiftUI

public protocol QueryRenderer {
    associatedtype Response
    
    associatedtype LoadingView: View
    associatedtype SuccessView: View
    associatedtype FailureView: View
    
    var loadingView: LoadingView { get }
    func successView(for response: Response) -> SuccessView
    func failureView(for failure: Error) -> FailureView
}

public extension QueryRenderer {
    func view(for state: QueryState<Response>) -> some View {
        switch state {
        case .idle, .loading:
            return AnyView(loadingView)
        case let .succeed(response):
            return AnyView(successView(for: response))
        case let .failed(failure):
            return AnyView(failureView(for: failure))
        }
    }
}
