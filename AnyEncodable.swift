//
//  AnyEncodable.swift
//  Moya
//
//  Created by Vitaly on 10/2/17.
//

import Foundation

public struct AnyEncodable<T>: Encodable {
    private let value: Encodable
    
    public init<U: Encodable>(_ encodable: U) {
        value = encodable
    }
    
    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
