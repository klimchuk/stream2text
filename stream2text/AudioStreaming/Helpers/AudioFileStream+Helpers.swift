//
//  AudioFileStream+Helpers.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import AVFoundation

@discardableResult
func fileStreamGetProperty<Value>(value: inout Value, fileStream streamId: AudioFileStreamID, propertyId: AudioFileStreamPropertyID) -> OSStatus {
    var (size, _) = fileStreamGetPropertyInfo(fileStream: streamId, propertyId: propertyId)
    let status = AudioFileStreamGetProperty(streamId, propertyId, &size, &value)
    guard status == noErr else {
        return status
    }
    return status
}

func fileStreamGetPropertyInfo(fileStream streamId: AudioFileStreamID, propertyId: AudioFileStreamPropertyID) -> (size: UInt32, status: OSStatus) {
    var valueSize: UInt32 = 0
    let status = AudioFileStreamGetPropertyInfo(streamId, propertyId, &valueSize, nil)
    guard status == noErr else {
        return (0, status)
    }
    return (valueSize, status)
}

///
/// Reference:
/// [Audio File Stream Errors](https://developer.apple.com/documentation/audiotoolbox/1391572-audio_file_stream_errors?language=objc)
public enum AudioFileStreamError: CustomDebugStringConvertible {
    case badPropertySize
    case dataUnavailable
    case discontinuityCantRecover
    case illegalOperation
    case invalidFile
    case invalidPacketOffset
    case notOptimized
    case unspecifiedError
    case unsupportedDataFormat
    case unsupportedFileType
    case unsupportedProperty
    case valueUnknown
    case unknownError
    case noError

    public init(status: OSStatus) {
        switch status {
        case kAudioFileStreamError_UnsupportedFileType:
            self = .unsupportedFileType
        case kAudioFileStreamError_UnsupportedDataFormat:
            self = .unsupportedDataFormat
        case kAudioFileStreamError_UnsupportedProperty:
            self = .unsupportedProperty
        case kAudioFileStreamError_BadPropertySize:
            self = .badPropertySize
        case kAudioFileStreamError_NotOptimized:
            self = .notOptimized
        case kAudioFileStreamError_InvalidPacketOffset:
            self = .invalidPacketOffset
        case kAudioFileStreamError_InvalidFile:
            self = .invalidFile
        case kAudioFileStreamError_ValueUnknown:
            self = .valueUnknown
        case kAudioFileStreamError_DataUnavailable:
            self = .dataUnavailable
        case kAudioFileStreamError_IllegalOperation:
            self = .illegalOperation
        case kAudioFileStreamError_UnspecifiedError:
            self = .unspecifiedError
        case kAudioFileStreamError_DiscontinuityCantRecover:
            self = .discontinuityCantRecover
        case noErr:
            self = .noError
        default:
            self = .unknownError
        }
    }

    public var debugDescription: String {
        switch self {
        case .badPropertySize:
            return "The size of the buffer you provided for property data was not correct."
        case .dataUnavailable:
            return "The amount of data provided to the parser was insufficient to produce any result."
        case .discontinuityCantRecover:
            return "A discontinuity has occurred in the audio data, and Audio File Stream Services cannot recover."
        case .illegalOperation:
            return "An illegal operation was attempted."
        case .invalidFile:
            return "The file is malformed, not a valid instance of an audio file of its type, or not recognized as an audio file."
        case .invalidPacketOffset:
            return "A packet offset was less than 0, or past the end of the file, or a corrupt packet size was read when building the packet table."
        case .notOptimized:
            return """
            It is not possible to produce output packets because the
            streamed audio file's packet table or other defining information is not present or appears after the audio data.
            """
        case .unspecifiedError:
            return "An unspecified error has occurred."
        case .unsupportedDataFormat:
            return "The data format is not supported by the specified file type."
        case .unsupportedFileType:
            return "The specified file type is not supported."
        case .unsupportedProperty:
            return "The property is not supported."
        case .valueUnknown:
            return "The property value is not present in this file before the audio data."
        case .unknownError:
            return "An unknown error occurred"
        case .noError:
            return "No error"
        }
    }
}
