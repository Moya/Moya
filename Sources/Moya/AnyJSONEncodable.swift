//
//  AnyJSONEncodable.swift
//  Moya
//
//  Created by Afonso Graça on 07/10/2017.
//

import Foundation

public struct AnyJSONEncodable: Encodable {

    // MARK: - Properties
    private let encodable: Encodable

    // MARK: - Initializers
    public init<E: Encodable>(_ encodable: E) {
        self.encodable = encodable
    }

    // MARK: - Encodable conformance
    public func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
