//
//  AddView.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/27/24.
//

import SwiftUI

struct AddView: View {
    @Binding var isPresented: Bool
    @Binding var textFieldValue1: String
    @Binding var textFieldValue2: String
    @FocusState private var focusedField: Field?
    
    let onSessionUpdated: (String, String) -> Void

        enum Field {
            case textField1
            case textField2
        }
    
    var body: some View {
        VStack {
            Text("Name")
            TextField("Enter name", text: $textFieldValue1)
                .focused($focusedField, equals: .textField1)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(10)
            Text("URL")
            TextField("Enter URL", text: $textFieldValue2)
                .focused($focusedField, equals: .textField2)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.URL)
                .textContentType(.URL)
                .padding(10)
            
            Button("Submit") {
                if textFieldValue1.count > 0 && textFieldValue2.count > 0 {
                    print("First value: \(textFieldValue1), Second value: \(textFieldValue2)")
                    onSessionUpdated(textFieldValue1, textFieldValue2)
                }
                self.isPresented = false
            }
        }
        .onAppear {
                   focusedField = .textField1 // Move focus to the first text field when the view appears
               }
        .frame(width: 300, height: 200)
        .padding(10).background(Color.white)
        .cornerRadius(20).shadow(radius: 10)
    }
}
