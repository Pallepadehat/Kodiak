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
    @Relationship(deleteRule: .cascade) var attachments: [ChatAttachment]
    
    init(content: String, isUser: Bool, chat: Chat? = nil) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.chat = chat
        self.sentiment = nil
        self.attachments = []
    }
}

@Model
class ChatAttachment {
    enum AttachmentType: String, Codable { case image, pdf }
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    var filename: String
    var sizeBytes: Int
    var ocrText: String?
    var thumbnailData: Data?
    var message: ChatMessage?
    
    var type: AttachmentType {
        get { AttachmentType(rawValue: typeRaw) ?? .image }
        set { typeRaw = newValue.rawValue }
    }
    
    init(type: AttachmentType, filename: String, sizeBytes: Int, message: ChatMessage? = nil) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.filename = filename
        self.sizeBytes = sizeBytes
        self.message = message
        self.ocrText = nil
        self.thumbnailData = nil
    }
}