//
//  QueryInvalidator.swift
//  Pigeon
//
//  Created by Fernando Martín Ortiz on 23/08/2020.
//  Copyright © 2020 Fernando Martín Ortiz. All rights reserved.
//

import Foundation

public struct QueryInvalidator {
    public enum Parameters {
        case lastData
        case newData(Any)
        
        func toTypedParameters<T>(of type: T.Type) -> TypedParameters<T>? {
            switch self {
            case .lastData:
                return .lastData
            case let .newData(newData):
                if let typedNewData = newData as? T {
                    return .newData(typedNewData)
                } else {
                    return nil
                }
            }
        }
    }
    
    public enum TypedParameters<T> {
        case lastData
        case newData(T)
        
        func erased() -> Parameters {
            switch self {
            case .lastData:
                return .lastData
            case let .newData(newData):
                return .newData(newData)
            }
        }
    }
    
    public func invalidateQuery(for key: QueryKey, with parameters: Parameters) {
        NotificationCenter.default.post(
            name: key.invalidationNotificationName,
            object: parameters
        )
    }
    
    public func invalidateQuery<T>(for key: QueryKey, with parameters: TypedParameters<T>) {
        NotificationCenter.default.post(
            name: key.invalidationNotificationName,
            object: parameters.erased()
        )
    }
}
