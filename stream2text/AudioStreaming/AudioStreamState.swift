//
//  AudioStreamState.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import AVFoundation

final class AudioStreamState {
    var processedDataFormat: Bool = false
    var dataOffset: UInt64 = 0
    var dataByteCount: UInt64?
    var dataPacketOffset: UInt64?
    var dataPacketCount: Double = 0
    var streamFormat = AudioStreamBasicDescription()
}
