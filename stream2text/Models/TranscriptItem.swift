//
//  TranscriptItem.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import Foundation

struct TranscriptItem : Identifiable, Hashable, Codable {

    var id = UUID()
    var timestamp: Date = Date()
    var showTimestamp: Bool? = false
    var text: String = ""
    
    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case showTimestamp
        case text
    }
    
    init(timestamp:Date?, text:String, st:Bool) {
        if let timestamp {
            self.timestamp = timestamp
        }
        self.text = text
        self.showTimestamp = st
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        timestamp = try values.decode(Date.self, forKey: .timestamp)
        showTimestamp = try values.decodeIfPresent(Bool.self, forKey: .showTimestamp)
        if showTimestamp == nil {
            showTimestamp = false
        }
        text = try values.decode(String.self, forKey: .text)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(showTimestamp, forKey: .showTimestamp)
        try container.encode(text, forKey: .text)
    }
        
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TranscriptItem, rhs: TranscriptItem) -> Bool {
        return lhs.id==rhs.id
    }
    
}
