//
//  AudioFragment.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import Foundation

struct AudioFragment {
    public var source:UnsafeMutableBufferPointer<Float>
    public var isNormalize = false
    
    var len: Int {
        source.count
    }
    
    init(from:UnsafeMutableBufferPointer<Float>, len:Int, isNormalize:Bool) {
        source = UnsafeMutableBufferPointer<Float>.allocate(capacity: len)
        source.initialize(from: from[0..<len])
        self.isNormalize = isNormalize
    }
    
    func normalize() -> UnsafeMutableBufferPointer<Float> {
        let maxAbsoluteValue = source.map { abs($0) }.max() ?? 1.0
        guard maxAbsoluteValue != 0 else { return source }
        
        for index in source.indices {
            source[index] = source[index] / maxAbsoluteValue
        }
        
        return source
    }
    
    func clear() {
        source.deallocate()
    }
}
