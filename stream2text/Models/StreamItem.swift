//
//  StreamItem.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import Foundation
import SwiftUI

class StreamItem : Identifiable, Hashable, Codable, ObservableObject {
    @ObservedObject private var settings = UserSettings.shared

    var id = UUID()
    var name: String = ""
    var url: String = ""
    var isStream: Bool = false
    @Published var items: [TranscriptItem] = []
    
    let dateFormatter = DateFormatter()
    
    var title:String  {
        get { 
            var s = name
            if items.count>0 {
                s += " ●"
            }
            return s
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case url
        case items
        case isStream
    }
    
    init(name:String, url:String) {
        self.name = name
        self.url = url
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        url = try values.decode(String.self, forKey: .url)
        items = try values.decode([TranscriptItem].self, forKey: .items)
        isStream = try values.decode(Bool.self, forKey: .isStream)

        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(items, forKey: .items)
        try container.encode(isStream, forKey: .isStream)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: StreamItem, rhs: StreamItem) -> Bool {
        return lhs.id==rhs.id
    }
    
    func setName(name: String) {
        self.name = name
    }
    
    func addTranscript(item: TranscriptItem) {
        self.items.append(item)
    }
    
    func getText() -> String {
        var body = ""
        if items.count > 0 {
            for s in items {
                if s.showTimestamp == true {
                    let timeStamp = dateFormatter.string(from: s.timestamp)
                    body.append("<\(timeStamp)>\n")
                }
                body.append(s.text+"\n")
            }
        }
        return body
    }

    func getDocument() -> TextFile {
        return TextFile(initialText: getText())
    }
    
    func getDefaultFilename() -> String {
        // Create Date
        let date = Date()

        // Create Date Formatter
        let dateFormatter = DateFormatter()

        // Set Date Format
        dateFormatter.dateFormat = "YY/MM/dd"

        // Convert Date to String
        let d = dateFormatter.string(from: date)
        
        return "\(name) \(d)"
    }
    
    func fetchFileContent(from urlString: String, completion: @escaping (Result<NetworkResult, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var mType:String?
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 3.0
        sessionConfig.timeoutIntervalForResource = 3.0
        let session = URLSession(configuration: sessionConfig)
        
        let urlRequest = URLRequest(url: url, timeoutInterval: 3.00)
        let task = session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                // If timeout we are dealing with stream not file
                self.isStream = true
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error fetching data"])))
                return
            }
            
            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Couldn't read data"])))
                return
            }
            
            // Extract the MIME type from the Content-Type header
            if let mimeType = httpResponse.allHeaderFields["Content-Type"] as? String {
                mType = mimeType
                print("MIME type: \(mimeType)")
                // Further processing depending on the MIME type
            } else {
                print("MIME type not found")
            }
            
            // Split the content into lines
            let lines = content.split(separator: "\n").map(String.init)
            completion(.success(NetworkResult(lines: lines, mimeType: mType)))
        }
        
        task.resume()
    }

    func getStreamURL(completion: @escaping (URL?) -> Void) {
        let u = url.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        var r:URL? = URL(string: u)
        
        // Download and extract URL
        fetchFileContent(from: u) { result in
            switch result {
            case .success(let result):
                    // pls
                if result.mimeType == "audio/x-scpls" || result.mimeType == "application/pls+xml" {
                    for line in result.lines {
                            if line.hasPrefix("File1=") {
                                var v = line.dropFirst(6).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                if v.count > 0 {
                                    r = URL(string: v)
                                    break
                                }
                            }
                        }
                } else if result.mimeType == "audio/x-mpegurl" {
                    for line in result.lines {
                            if line.hasPrefix("http") {
                                var v = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                if v.count > 0 {
                                    r = URL(string: v)
                                    break
                                }
                            }
                        }
                    }
            case .failure(let error):
                print("Failed to fetch file: \(error)")
            }
            
            completion(r)
        }
    }
}
