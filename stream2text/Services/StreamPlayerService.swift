//
//  StreamPlayerService.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import AVFoundation

protocol AudioPlayerServiceDelegate: AnyObject {
    func didStartPlaying()
    func didStopPlaying()
    func statusChanged(status: AudioPlayerState)
    func errorOccurred(error: AudioPlayerError)
    func metadataReceived(metadata: [String: String])
    func lastMessageUpdated(message: String)
}

fileprivate class Box<ResultType> {
    var result: Result<ResultType, Error>? = nil
}

final class StreamPlayerService : ObservableObject {
    static let shared = StreamPlayerService()
    
    var isModelLoaded = false
    var messageLog = ""
    var streamTitle = ""
    var canTranscribe = false
    var isPaused = false;
    
    public var session: StreamItem?
    var timestamp: Date?
    
    var delegate = MulticastDelegate<AudioPlayerServiceDelegate>()
    
    var started = 0
    
    // For streams
    private var player: AudioPlayer?
    private var audioSystemResetObserver: Any?
    
    private var isRecorder = false
    private var recorder: AudioRecorder?
    
    private var whisperContext: WhisperContext?
    
    private var internalQueue:Queue<AudioFragment>?
    
    //var timer: Timer?
    
    // Max length is 5 seconds with 16kHz
    static let MAX_OFFSET = 80000
    var p = UnsafeMutableBufferPointer<Float>.allocate(capacity: MAX_OFFSET)
    var poffset = 0
    var plen = 0;
    //
    let pattern = "\\([^)]*\\)|\\[.*?\\]"
    
    let dateFormatter = DateFormatter()

    var durationText:String {
        if started == 0 {
            return "0:00"
        } else {
            return timeFrom(seconds: Int(Date().timeIntervalSince1970) - started)
        }
    }

    var isMuted: Bool {
        isPaused
    }

    var state: AudioPlayerState {
        if isRecorder {
            recorder!.state
        } else {
            if player == nil {
                AudioPlayerState.stopped
            } else {
                player!.state
            }
        }
    }
    
    var isCanTranscribe: Bool {
        canTranscribe
    }
    
    private func timeFrom(seconds: Int) -> String {
        let correctSeconds = seconds % 60
        let minutes = (seconds / 60) % 60
        let hours = seconds / 3600

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, correctSeconds)
        }
        return String(format: "%d:%02d", minutes, correctSeconds)
    }
    
    private var modelUrl: URL? {
        let path = Bundle.main.path(forResource: "ggml-medium.en", ofType: "bin")
        return URL(fileURLWithPath: path!)
    }

    init() {
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        
        internalQueue = Queue<AudioFragment>()

        DispatchQueue.global(qos: .background).async {
            do {
                try self.loadModel()
                self.canTranscribe = true
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    public func setRecorder(isRecorder:Bool) {
        self.isRecorder = isRecorder
        recreatePlayerRecorder()
    }
    
    private func loadModel() throws {
        messageLog += "Loading model...\n"
        if let modelUrl {
            if #available(iOS 16.0, *) {
                whisperContext = try WhisperContext.createContext(path: modelUrl.path())
            } else {
                // Fallback on earlier versions
            }
            messageLog += "Loaded model \(modelUrl.lastPathComponent)\n"
        } else {
            messageLog += "Could not locate model\n"
        }
    }
    
    private func transcribeAudio(_ buffer: AVAudioPCMBuffer) {
        if (!canTranscribe) {
            return
        }
        guard let whisperContext else {
            return
        }
        
        if poffset==0 {
            timestamp = Date()
        }
        
        do {
            canTranscribe = false
            messageLog += "Transcribing data...\n"
            
            /*var channelCount:AVAudioChannelCount
            if isRecorder {
                channelCount = 1
            } else {
                channelCount = player!.mainMixerNode.outputFormat(forBus: 0).channelCount
            }*/
            let frameLength = Int(buffer.frameLength)
            let stride = buffer.stride
            
            var silence = true
            // If recorder active then sample rate is 48kHz so only every 3rd value is important
            for sampleIndex in Swift.stride(from: 1, to: frameLength, by: isRecorder ? 3:1) {
            //for sampleIndex in 0 ..< frameLength {
                var sum:Float = 0.0
                // Loop across our channels...
                //let channel = 0
                //for channel in 0 ..< channelCount {
                    sum += buffer.floatChannelData?[Int(0)][sampleIndex * stride] ?? 0
                //}
                if abs(sum)>0.005 || isRecorder {
                    silence = false
                    //
                    p[poffset] = sum//Float(channelCount)
                    poffset+=1
                    plen+=1
                    if plen==StreamPlayerService.MAX_OFFSET {
                        break
                    }
                }
            }
            
            var process=false
            if silence {
                // Less than 3 seconds doesn't make sense
                if plen>48000 {
                    process = true
                }
            } else {
                if plen==StreamPlayerService.MAX_OFFSET {
                    process = true
                }
            }
            if process
            {
                let af = AudioFragment(from: self.p, len:self.plen, isNormalize: false)
                print("Queue \(self.plen)")
                DispatchQueue.global(qos: .background).async {
                    self.internalQueue?.enqueue(item: af)
                }
                poffset = 0
                plen = 0
            }

        } catch {
            print(error.localizedDescription)
            messageLog += "\(error.localizedDescription)\n"
        }
        
        canTranscribe = true
    }
    
    func cleanupTranscription(text: String) -> String {
        // Attempt to create a regular expression object
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            // Use the regex to replace matches with an empty string
            let range = NSRange(text.startIndex..., in: text)
            let cleanedText = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
            
            return cleanedText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        
        return text
    }
    
    /// Unsafely awaits an async function from a synchronous context.
    @available(*, deprecated, message: "Migrate to structured concurrency")
    func _unsafeWait<ResultType>(_ f: @escaping () async throws -> ResultType) throws -> ResultType {
        let box = Box<ResultType>()
        let sema = DispatchSemaphore(value: 0)
        Task {
            do {
                let val = try await f()
                box.result = .success(val)
            } catch {
                box.result = .failure(error)
            }
            sema.signal()
        }
        sema.wait()
        return try box.result!.get()
    }

    func play(url: URL?, session: StreamItem) {
        self.session = session
        activateAudioSession()
        
        if isRecorder {
            recorder!.play()
        } else {
            player!.play(url: url!)
        }
        //
        started = Int(Date().timeIntervalSince1970)
        poffset = 0
        plen = 0
        //timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
        //    self?.processQueue()
        //}
        DispatchQueue.global(qos: .background).async {
            self.processQueue()
        }
    }

    func processQueue() {
        print("Process started")
        while self.session != nil {
            let p = internalQueue?.dequeue()
            if p != nil && p!.len > 0 {
                do {
                    try _unsafeWait { [self] in
                        if p!.isNormalize {
                            await whisperContext?.fullTranscribe(samples: p!.normalize(), len:Int32(p!.len))
                        } else {
                            await whisperContext?.fullTranscribe(samples: p!.source, len:Int32(p!.len))
                        }
                        return
                    }
                    let text = try _unsafeWait { [self] in
                        let (text) = try await whisperContext?.getTranscription()
                        return text
                    }
                    let m = "\(String(describing: text))\n"
                    print(m)
                    let x = cleanupTranscription(text: (text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))!)
                    if x.count>0 {
                        DispatchQueue.main.sync {
                            var showTimestamp = true
                            if let l = self.session?.items.last {
                                let timeStampOld = dateFormatter.string(from: l.timestamp)
                                let timeStampNew = dateFormatter.string(from: timestamp!)
                                if timeStampNew == timeStampOld {
                                    showTimestamp = false
                                }
                            }
                            session?.addTranscript(item: TranscriptItem(timestamp: timestamp, text: x, st: showTimestamp))
                            delegate.invoke(invocation: { $0.lastMessageUpdated(message: m) })
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                    messageLog += "\(error.localizedDescription)\n"
                }
                p?.clear()
            }
            else
            {
                sleep(1)
            }
        }
        print("Process finished")
    }
    
    func stop() {
        streamTitle = ""
        poffset = 0
        plen = 0
        started = 0
        //
        session = nil
        
        if isRecorder {
            recorder!.stop()
        } else {
            player!.stop()
        }
        deactivateAudioSession()
        internalQueue?.removeAll()
    }

    private func setFilter() {
        
        if isRecorder {
            recorder!.setFilter(name: "record") { buffer, when in
                //try? audioFile?.write(from: buffer)
                self.transcribeAudio(buffer)
            }
        } else {
            let record = FilterEntry(name: "record") { buffer, when in
                //try? audioFile?.write(from: buffer)
                self.transcribeAudio(buffer)
            }

            player!.frameFiltering.add(entry: record)
        }
    }

    private func recreatePlayerRecorder() {
        if isRecorder {
            // We need recorder
            if player != nil {
                player?.stop()
                player = nil
            }
            if recorder == nil {
                recorder = AudioRecorder()
                setFilter()
                configureAudioSession()
            }
        } else {
            // We need player
            if recorder != nil {
                recorder?.stop()
                recorder = nil
            }
            if player == nil {
                player = AudioPlayer(configuration: .init(enableLogs: true))
                player!.delegate = self
                setFilter()
                
                configureAudioSession()
                registerSessionEvents()
            }
        }
    }

    private func registerSessionEvents() {
        // Note that a real app might need to observer other AVAudioSession notifications as well
        audioSystemResetObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification,
                                                                          object: nil,
                                                                          queue: nil) { [unowned self] _ in
            self.configureAudioSession()
            if isRecorder {
            } else {
                player = AudioPlayer(configuration: .init(enableLogs: true))
                player!.delegate = self
                setFilter()
            }
        }
    }

    private func configureAudioSession() {
        do {
            if isRecorder {
                print("AudioSession category is AVAudioSessionCategoryRecord")
                try AVAudioSession.sharedInstance().setCategory(.record, mode: .default)
            } else {
                print("AudioSession category is AVAudioSessionCategoryPlayback")
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio, options: [])
            }
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.1)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch let error as NSError {
            print("Couldn't setup audio session category to Playback \(error.localizedDescription)")
        }
    }

    private func activateAudioSession() {
        do {
            print("AudioSession is active")
            try AVAudioSession.sharedInstance().setActive(true, options: [])

        } catch let error as NSError {
            print("Couldn't set audio session to active: \(error.localizedDescription)")
        }
    }

    private func deactivateAudioSession() {
        do {
            print("AudioSession is deactivated")
            try AVAudioSession.sharedInstance().setActive(false)
        } catch let error as NSError {
            print("Couldn't deactivate audio session: \(error.localizedDescription)")
        }
    }
}

extension StreamPlayerService: AudioPlayerDelegate {
    func audioPlayerDidStartPlaying(player _: AudioPlayer, with _: AudioEntryId) {
        delegate.invoke(invocation: { $0.didStartPlaying() })
    }

    func audioPlayerDidFinishBuffering(player _: AudioPlayer, with _: AudioEntryId) {}

    func audioPlayerStateChanged(player _: AudioPlayer, with newState: AudioPlayerState, previous _: AudioPlayerState) {
        delegate.invoke(invocation: { $0.statusChanged(status: newState) })
    }

    func audioPlayerDidFinishPlaying(player _: AudioPlayer,
                                     entryId _: AudioEntryId,
                                     stopReason _: AudioPlayerStopReason,
                                     progress _: Double,
                                     duration _: Double)
    {
        delegate.invoke(invocation: { $0.didStopPlaying() })
    }

    func audioPlayerUnexpectedError(player _: AudioPlayer, error: AudioPlayerError) {
        delegate.invoke(invocation: { $0.errorOccurred(error: error) })
    }

    func audioPlayerDidCancel(player _: AudioPlayer, queuedItems _: [AudioEntryId]) {}

    func audioPlayerDidReadMetadata(player _: AudioPlayer, metadata: [String: String]) {
        if metadata["StreamTitle"] != nil {
            self.streamTitle = metadata["StreamTitle"]!
        }
        delegate.invoke(invocation: { $0.metadataReceived(metadata: metadata) })
    }
}
