//
//  MessageView.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import SwiftUI
import FoundationModels

struct MessageView: View {
    let segments: [Transcript.Segment]
    
    let isUser: Bool
    
    
    var body: some View {
        VStack {
            ForEach(segments, id: \.id) { segment in
                switch segment {
                case .text(let text):
                    Text(text.content).padding(10)
                        .background(isUser ? Color.gray.opacity(0.2) : .clear, in:.rect(cornerRadius: 12))
                        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
                    
                case .structure:
                    EmptyView()
                    
                @unknown default:
                    EmptyView()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}


