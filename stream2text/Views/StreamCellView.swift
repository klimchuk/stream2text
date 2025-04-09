//
//  StreamCellView.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import SwiftUI

struct StreamCellView: View {
    @ObservedObject var player = StreamPlayerService.shared
    @State var item: StreamItem
    
    var body: some View {
        if item.id == player.session?.id {
            Text("► \(item.title)")
        } else {
            Text("\(item.title)")
        }
    }
}

/*#Preview {
    StreamCellView(item: StreamItem(), onSessionUpdated: ())
}*/
