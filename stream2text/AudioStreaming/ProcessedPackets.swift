//
//  ProcessedPackets.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import Foundation

final class ProcessedPacketsState {
    var bufferSize: UInt32 = 0
    var count: UInt32 = 0
    var sizeTotal: UInt32 = 0

    var isEmpty: Bool {
        count == 0
    }
}
