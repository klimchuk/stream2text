//
//  Atomic.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import Foundation

final class Atomic<Value> {
    private let lock = UnfairLock()
    private var _value: Value

    init(_ value: Value) {
        _value = value
    }

    var value: Value { lock.withLock { _value } }

    func write(_ transform: (inout Value) -> Void) {
        lock.withLock { transform(&self._value) }
    }
}

extension Atomic: Equatable where Value: Equatable {
    static func == (lhs: Atomic, rhs: Atomic) -> Bool {
        lhs.value == rhs.value
    }
}

extension Atomic: Hashable where Value: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

extension Atomic: Comparable where Value: Comparable {
    static func < (lhs: Atomic<Value>, rhs: Atomic<Value>) -> Bool {
        lhs.value < rhs.value
    }
}
