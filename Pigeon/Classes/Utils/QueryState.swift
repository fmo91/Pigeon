//
//  QueryTypes.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation
import Combine

public enum QueryState<Response> {
    case idle
    case loading
    case succeed(Response)
    case failed(Error)
    
    public var value: Response? {
        if case let .succeed(value) = self {
            return value
        } else {
            return nil
        }
    }
}
