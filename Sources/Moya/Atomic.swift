//
//  Atomic.swift
//  Moya
//
//  Created by Luciano Almeida on 15/12/19.
//

import Foundation

@propertyWrapper
final class Atomic<Value> {
    private var lock: NSRecursiveLock = NSRecursiveLock()

    private var value: Value

    var wrappedValue: Value {
        get {
            lock.lock(); defer { lock.unlock() }
            return value
        }

        set {
            lock.lock(); defer { lock.unlock() }
            value = newValue
        }
    }

    init(wrappedValue value: Value) {
        self.value = value
    }
}
