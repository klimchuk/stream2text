//
//  ContentView.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/20/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var settings = UserSettings.shared
    
    @State var sessions: [StreamItem] = []
    @State private var selection: StreamItem?
    @State var showAdd = false
    @State var v1 = ""
    @State var v2 = ""
    @State var showSettings = false
    
    let fs = FileService()

    var body: some View {
        //TextEditor(text: $document.text)
        NavigationSplitView {
            Text("Stations")
            
            Button {
                self.showAdd = true
            } label: {
                Label("Add", systemImage: "note.text.badge.plus")
            }.alert("Add station", isPresented: $showAdd) {
                TextField("Enter name", text: $v1)
                TextField("Enter URL or leave empty", text: $v2)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                Button("OK") {
                    sessionAdded(name: v1, url: v2)
                    v1 = ""
                    v2 = ""
                }
                Button("Cancel", role: .cancel) {
                    v1 = ""
                    v2 = ""
                }
            }.toolbar(content: {
                Button {
                    self.showSettings.toggle()
                } label: {
                    Label("Settings", systemImage: settings.isAutosave ? "gearshape.fill" : "gearshape")
                }
            }).alert("Settings", isPresented: $showSettings) {
                Text("Autosave transcripts?")
                Button("Yes") {
                    settings.isAutosave = true
                    settings.save()
                }
                Button("No", role: .cancel) {
                    settings.isAutosave = false
                    settings.save()
                }
            }

            List(selection: $selection){
                ForEach(sessions, id: \.self) { s in
                    NavigationLink(value: s) {
                        StreamCellView(item: s)
                    }
                }.onDelete(perform: delete)
                }
            }
            detail: {
                if selection != nil {
                    StreamDetailView(session: selection!, 
                                     onSaveSession: saveSessions)
              } else {
                Text("Add new station using button above")
              }
            }.onAppear(perform: {
                settings.load()
                if sessions.count == 0 {
                    loadSessions()
                }
            }).listStyle(PlainListStyle()).navigationTitle("Stations")
    }
    
    func checkboxSelected(id: String, isMarked: Bool) {
            print("\(id) is marked: \(isMarked)")
        }
    
    func sessionAdded(name: String, url: String) {
        if url.count == 0 {
            sessions.insert(StreamItem(name: name+"🎤", url: url), at:0)
        } else {
            sessions.insert(StreamItem(name: name, url: url), at:0)
        }
        saveSessions()
    }
    
    func delete(at offsets: IndexSet) {
        self.sessions.remove(atOffsets: offsets)
        saveSessions()
    }
    
    func saveSessions() {
        // Save
        if let encodedData = try? JSONEncoder().encode(self.sessions) {
            //let jsonString = String(data: encodedData, encoding:.utf8)
            try? fs.save(fileNamed: "default", data: encodedData)
        }
    }
    
    func loadSessions()
    {
        if let data = try? fs.read(fileNamed: "default") {
            let newSessions = try! JSONDecoder().decode([StreamItem].self, from: data)
            self.sessions = newSessions
        }
        if self.sessions.count == 0 {
            // Add demos
            let mic = StreamItem(name: "Voice notes🎤", url:"")
            self.sessions.append(mic)
            let nir = StreamItem(name: "News Internet Radio", url:"https://stream.rcast.net/m3u/256661")
            self.sessions.append(nir)
            let bbc = StreamItem(name: "BBC World Service", url:"https://vprbbc.streamguys1.com:443/vprbbc24.mp3")
            self.sessions.append(bbc)
            let nbc = StreamItem(name: "NBC News Radio", url:"http://peridot.streamguys.com:7850/live")
            self.sessions.append(nbc)
            let artbell = StreamItem(name: "Art Bell", url:"https://stream.willstare.com:8450")
            self.sessions.append(artbell)
            var demo = StreamItem(name: "KJFK Tower", url: "http://d.liveatc.net/kjfk_twr")
            self.sessions.append(demo)
            /*demo = StreamItem(name: "KEWR Ground", url: "http://d.liveatc.net/kewr_gnd_pri")
            self.sessions.append(demo)
            demo = StreamItem(name: "KEWR NY Approach (North)", url: "http://d.liveatc.net/kewr_app_n")
            self.sessions.append(demo)
            demo = StreamItem(name: "KEWR Tower", url: "http://d.liveatc.net/kewr_twr")
            self.sessions.append(demo)
            demo = StreamItem(name: "KEWR Departure 128.8", url: "http://d.liveatc.net/kewr_app_n_arr2")
            self.sessions.append(demo)
            demo = StreamItem(name: "KEWR Departure 120.85 (Liberty West)", url: "http://d.liveatc.net/kewr_dep_lib_w")
            self.sessions.append(demo)*/
        }
    }
}

#Preview {
    ContentView()
}
