//
//  StreamDetailView.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import Combine
import SwiftUI

struct StreamDetailView: View {
    @ObservedObject private var settings = UserSettings.shared
    
    @ObservedObject var session: StreamItem
    @ObservedObject var player = StreamPlayerService.shared
    @State private var bottomMessage = "Loading... "
    @State private var duration = "0:00"
    @State private var loaded = false
    @State private var showingExporter = false
    @State private var yourDocument:TextFile?
    @State var showExport = false
    @State var sharedContent: [Any] = []
    @State var showClearAll = false
    @State var showEdit = false
    @State var readingFile = false
    @State var v1 = ""
    @State var v2 = ""
    
    @State private var bufferingTimestamp:Date?
    
    let onSaveSession: () -> Void
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollViewReader { proxy in
                VStack {
                    HStack {
                        Button {
                            showClearAll.toggle()
                        } label: {
                            Label("Clear All", systemImage: "clear")
                        }.alert("Clear All?", isPresented: $showClearAll) {
                            Button("Yes", action: clearAll)
                            Button("No", role: .cancel) { }
                        }
                                                
                        Button {
                            v1 = session.name
                            v2 = session.url
                            showEdit.toggle()
                        } label: {
                            Label("Edit", systemImage: "applepencil")
                        }.alert("Edit station", isPresented: $showEdit) {
                                TextField("Enter name", text: $v1)
                                if session.url.count > 0 {
                                    TextField("Enter URL", text: $v2)
                                        .keyboardType(.URL)
                                        .textContentType(.URL)
                                        .textInputAutocapitalization(.never)
                                }
                                Button("OK", action: sessionUpdated)
                                Button("Cancel", role: .cancel) { }
                        }
                    }
                    
                    if player.streamTitle.count > 0 {
                        Text("\(player.streamTitle)").foregroundColor(.blue).padding(8) // Adjust padding to control the
                            .border(Color.purple, width: 3)
                    }
                    ScrollView {
                        ScrollViewReader { scrollViewReader in
                            // solves the reuse / performance for scrollview and we dont need to use ListView
                            LazyVStack {
                                ForEach($session.items, id: \.self) { s in
                                    TranscriptCellView(s.wrappedValue)
                                        .frame(maxWidth: .infinity)
                                        .id(s.wrappedValue)
                                }
                                
                            }
                            .onReceive(Just($session.items)) { _ in
                                withAnimation {
                                    proxy.scrollTo($session.items.last?.wrappedValue, anchor: .bottom)
                                    if settings.isAutosave {
                                        onSaveSession()
                                    }
                                }
                            }
                        }
                    }
                    // text and send button
                    HStack {
                        Spacer()
                        Text(bottomMessage).frame(width: 120.0).onReceive(timer) { _ in
                            // Increment the counter every second
                            duration = player.durationText
                            loaded = player.isCanTranscribe
                            if loaded && readingFile == false {
                                switch player.state {
                                case .ready,.stopped,.error,.disposed,.paused:
                                    bottomMessage = "Press Play "
                                    self.bufferingTimestamp = nil
                                case .running,.playing:
                                    bottomMessage = "Transcribing... "
                                    self.bufferingTimestamp = nil
                                case .bufferring:
                                    bottomMessage = "Buffering... "
                                    // If we have 15 seconds of buffering drop to stop
                                    if bufferingTimestamp == nil {
                                        self.bufferingTimestamp = Date()
                                    } else {
                                        if Date().timeIntervalSince1970 - self.bufferingTimestamp!.timeIntervalSince1970 > 15.0 {
                                            self.bufferingTimestamp = nil
                                            player.stop()
                                        }
                                    }
                                }
                            } else {
                                bottomMessage = "Loading... "
                            }
                        }
                        if readingFile {
                            ProgressView().font(.title)
                                .foregroundColor(.blue)
                                .padding(3)
                        } else {
                            switch player.state {
                            case .ready,.stopped,.error,.disposed,.paused:
                                if loaded {
                                    Button(action: {
                                        if session.url.count == 0 {
                                            // Recorder
                                            player.setRecorder(isRecorder: true)
                                            player.play(url: nil, session: session)
                                        } else {
                                            if session.isStream {
                                                // We know it's stream
                                                UIApplication.shared.isIdleTimerDisabled = true
                                                player.setRecorder(isRecorder: false)
                                                player.play(url: URL(string: session.url)!, session: session)
                                            }
                                            else {
                                                readingFile = true
                                                session.getStreamURL() { url in
                                                    if url != nil {
                                                        print("URL: \(String(describing: url))")
                                                        
                                                        DispatchQueue.main.sync {
                                                            UIApplication.shared.isIdleTimerDisabled = true
                                                        }
                                                        player.setRecorder(isRecorder: false)
                                                        player.play(url: url!, session: session)
                                                    }
                                                    readingFile = false
                                                }
                                            }
                                        }
                                    }) { Label("", systemImage: "play.circle").foregroundColor(session.url.count == 0 ? .red : .blue).font(.system(size: 30))/*Text("▶︎")
                                            .font(.title)
                                            .foregroundColor(.blue)
                                        .padding(3)*/ }
                                } else {
                                    ProgressView().font(.title)
                                        .foregroundColor(.blue)
                                        .padding(3)
                                }
                            case .running,.playing:
                                Button(action: {
                                    player.stop()
                                    UIApplication.shared.isIdleTimerDisabled = false
                                }) { Label("", systemImage: "stop.circle").foregroundColor(player.session?.url.count == 0 ? .red : .blue).font(.system(size: 30))/*Text("◼︎")
                                        .font(.title)
                                        .foregroundColor(.blue)
                                    .padding(3)*/ }
                            case .bufferring:
                                ProgressView().font(.title)
                                    .foregroundColor(.blue)
                                    .padding(3)
                            }
                        }
                        
                        if duration != "0:00" {
                            Text("\(duration)").font(.title).frame(width: 120.0)
                        }
                        Spacer()
                    }.padding()
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    withAnimation {
                        proxy.scrollTo($session.items.last?.wrappedValue, anchor: .bottom)
                    }
            }
        }.navigationTitle(session.name).toolbar(content: {
                Button {
                    sharedContent = [ session.getText() ]
                    self.showExport.toggle()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }).sheet(isPresented: $showExport) {
                        ActivityViewController(activityItems: $sharedContent)
                    }
            
    }
        
    func clearAll() {
        session.items.removeAll()
        onSaveSession()
    }
    
    func sessionUpdated() {
        session.name = v1
        session.url = v2
        session.isStream = false
        onSaveSession()
    }
    
    
}

/*#Preview {
    StreamDetailView()
}*/
