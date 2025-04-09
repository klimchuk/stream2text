//
//  AudioRecorder.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 4/5/24.
//

import Foundation
import AVFoundation

open class AudioRecorder {
    private let audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    private var audioSession: AVAudioSession?
    
    private var atomicState: Atomic<AudioPlayerState>
    
    public var name: String?
    public var filter: FilterCallback?

    init() {
        self.atomicState = Atomic(AudioPlayerState.ready)
    }
    
    public func setFilter(name: String, filter: @escaping FilterCallback) {
        self.name = name
        self.filter = filter
    }
    
    public var state: AudioPlayerState {
        atomicState.value
    }

    private func setupMicrophone() {
        /*do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure AVAudioSession: \(error)")
        }*/
        
        

    }
    
    func play() {
        AVAudioSession.sharedInstance().requestRecordPermission { [self] granted in
            if granted {
                
                // Permission granted, proceed with microphone access
                //guard let inputNode = inputNode, let format = format else { return }
                /*do {
                    // Activate the session.
                    audioSession = AVAudioSession.sharedInstance()
                    guard let audioSession = audioSession else { return }
                    try audioSession.setActive(false)
                    try audioSession.setCategory(.record, mode: .default)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                } catch {
                    print("Could not start audio session: \(error.localizedDescription)")
                }*/
                inputNode = audioEngine.inputNode
                guard let inputNode = inputNode else { return }
                
                // Use the input node's output format. Modify as needed for your use case.
                let format = inputNode.outputFormat(forBus: 0)
                
                let desiredFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)

                //AudioOutputUnitStop((audioEngine.inputNode.audioUnit)!)

                //AudioUnitUninitialize((audioEngine.inputNode.audioUnit)!)

                // Take 1/10th of the second
                inputNode.installTap(onBus: 0, bufferSize: UInt32(format.sampleRate)/10, format: format) { [self] buffer, when in
                    // Here you can process or stream the buffer
                    // For example, convert buffer to data and stream it
                    if let filter {
                        filter(buffer, when)
                    }
                }
                
                audioEngine.prepare()

                do {
                    try audioEngine.start()
                    
                    self.atomicState = Atomic(AudioPlayerState.playing)
                } catch {
                    self.atomicState = Atomic(AudioPlayerState.stopped)
                    print("Could not start audio engine: \(error.localizedDescription)")
                }
            } else {
                // Permission denied, handle accordingly
            }
        }
    }
    
    func stop() {
        self.atomicState = Atomic(AudioPlayerState.stopped)
        audioEngine.stop()
        AudioOutputUnitStop((audioEngine.inputNode.audioUnit)!)
        AudioUnitUninitialize((audioEngine.inputNode.audioUnit)!)
        inputNode?.removeTap(onBus: 0)
        //audioEngine.reset()
    }
}
