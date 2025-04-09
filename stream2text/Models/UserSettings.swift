//
//  UserSettings.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 4/5/24.
//

import Foundation

class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    @Published var isAutosave:Bool = false
    
    public func load() {
        let defaults = UserDefaults.standard
        
        self.isAutosave = defaults.bool(forKey: "isAutosave")
    }
    
    public func save() {
        let defaults = UserDefaults.standard
        
        defaults.setValue(self.isAutosave, forKeyPath: "isAutosave")
    }
}
