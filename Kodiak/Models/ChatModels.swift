//
//  ChatModels.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import Foundation
import SwiftData
import FoundationModels

@Model
class Chat {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    @Relationship(deleteRule: .cascade) var messages: [ChatMessage]
    
    init(title: String = "Untitled Chat") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPinned = false
        self.messages = []
    }
}

@Model
class ChatMessage {
    @Attribute(.unique) var id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date
    var chat: Chat?
    // Stores user feedback on assistant responses: "positive", "negative", or nil
    var sentiment: String?
    
    init(content: String, isUser: Bool, chat: Chat? = nil) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.chat = chat
        self.sentiment = nil
    }
}