//
//  TranscriptCellView.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import SwiftUI

struct TranscriptCellView: View {
    @State var item: TranscriptItem
    
    let dateFormatter = DateFormatter()
    
    init(_ xitem: TranscriptItem) {
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        _item = State(initialValue:xitem)
    }
    
    var body: some View {
        let timeStamp = dateFormatter.string(from: item.timestamp)
        
        //Text("\(timeStamp)> \(item.text)").multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/).padding(5)
        
        VStack(alignment: .leading) {
            if item.showTimestamp == true {
                // header
                HStack {
                    Text("\(timeStamp)")
                        .bold()
                    Spacer() // Spacer here!
                }
                .foregroundStyle(.secondary)
            }
                    // text
                    Text("\(item.text)")
                }
        .padding(10)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)
                .frame(maxWidth: 350, alignment: .leading)
    }
}
