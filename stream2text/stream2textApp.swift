//
//  stream2textApp.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/20/24.
//

import SwiftUI

@main
struct stream2textApp: App {
    private var defaultColor: Color = Color(red: 0.337, green: 0.337, blue: 0.620)
    
    var body: some Scene {
        WindowGroup {
            ContentView().accentColor(defaultColor)
        }
    }
}
