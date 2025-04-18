//
//  AudioConverter+Helpers.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import AVFoundation

public enum AudioConverterError: CustomDebugStringConvertible {
    case badPropertySizeError
    case formatNotSupported
    case inputSampleRateOutOfRange
    case invalidInputSize
    case invalidOutputSize
    case operationNotSupported
    case outputSampleRateOutOfRange
    case propertyNotSupported
    case requiresPacketDescriptionsError
    case unspecifiedError

    init(osstatus: OSStatus) {
        switch osstatus {
        case kAudioConverterErr_BadPropertySizeError:
            self = .badPropertySizeError
        case kAudioConverterErr_FormatNotSupported:
            self = .formatNotSupported
        case kAudioConverterErr_InputSampleRateOutOfRange:
            self = .inputSampleRateOutOfRange
        case kAudioConverterErr_InvalidInputSize:
            self = .invalidInputSize
        case kAudioConverterErr_InvalidOutputSize:
            self = .invalidOutputSize
        case kAudioConverterErr_OperationNotSupported:
            self = .operationNotSupported
        case kAudioConverterErr_OutputSampleRateOutOfRange:
            self = .outputSampleRateOutOfRange
        case kAudioConverterErr_PropertyNotSupported:
            self = .propertyNotSupported
        case kAudioConverterErr_RequiresPacketDescriptionsError:
            self = .requiresPacketDescriptionsError
        case kAudioConverterErr_UnspecifiedError:
            self = .unspecifiedError
        default:
            self = .unspecifiedError
        }
    }

    public var debugDescription: String {
        switch self {
        case .badPropertySizeError:
            return "Bad property size"
        case .formatNotSupported:
            return "Format not supported"
        case .inputSampleRateOutOfRange:
            return "Input sample rate is out of range"
        case .invalidInputSize:
            return "Invalid input size"
        case .invalidOutputSize:
            return "The byte size is not an integer multiple of the frame size."
        case .operationNotSupported:
            return "Operation not supported"
        case .outputSampleRateOutOfRange:
            return "Output sample rate out of range"
        case .propertyNotSupported:
            return "Property not supported"
        case .requiresPacketDescriptionsError:
            return "Required packet descriptions (error)"
        case .unspecifiedError:
            return "Unspecified error "
        }
    }
}
