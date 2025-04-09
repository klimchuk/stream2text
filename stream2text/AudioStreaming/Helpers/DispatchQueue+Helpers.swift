//
//  DispatchQueue+Helpers.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import Foundation

/// Helper method to dispatch the given block asynchronously on the MainQueue
func asyncOnMain(_ block: @escaping () -> Void) {
    DispatchQueue.main.async(execute: block)
}

/// Helper method to dispatch the given block asynchronously on the MainQueue, after a given time interval
/// - note: This account for `.now()` plus the passed deadline
func asyncOnMain(deadline: DispatchTimeInterval, block: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + deadline, execute: block)
}
