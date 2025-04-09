//
//  BufferContext.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import Foundation

final class BufferContext {
    let sizeInBytes: UInt32
    let totalFrameCount: UInt32

    var frameStartIndex: UInt32 = 0
    var frameUsedCount: UInt32 = 0

    var end: UInt32 {
        (frameStartIndex + frameUsedCount) % totalFrameCount
    }

    init(sizeInBytes: UInt32, totalFrameCount: UInt32) {
        self.sizeInBytes = sizeInBytes
        self.totalFrameCount = totalFrameCount
    }

    func reset() {
        frameStartIndex = 0
        frameUsedCount = 0
    }
}
