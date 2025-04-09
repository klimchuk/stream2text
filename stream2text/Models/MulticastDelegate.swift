//
//  MulticastDelegate.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import Foundation

class MulticastDelegate<Delegate> {
    private let delegates = NSHashTable<AnyObject>.weakObjects()

    func add(delegate: Delegate) {
        delegates.add(delegate as AnyObject)
    }

    func remove(delegate: Delegate) {
        for oneDelegate in delegates.allObjects.reversed() {
            if oneDelegate === delegate as AnyObject {
                delegates.remove(oneDelegate)
            }
        }
    }

    func invoke(invocation: (Delegate) -> Void) {
        for delegate in delegates.allObjects.reversed() {
            invocation(delegate as! Delegate)
        }
    }
}
