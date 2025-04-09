//
//  AVAudioFormat+Convenience.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import AVFoundation

public extension AVAudioFormat {
    /// The underlying audio stream description.
    ///
    /// This exposes the `pointee` value of the `UsafePointer<AudioStreamBasicDescription>`
    var basicStreamDescription: AudioStreamBasicDescription {
        return streamDescription.pointee
    }
}
