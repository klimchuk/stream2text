//
//  SeekRequest.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import Foundation

final class SeekRequest {
    let lock = UnfairLock()
    var requested: Bool = false
    var version = Atomic<Int>(0)
    var time: Double = 0
}
