//
//  ChatManager.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class ChatManager {
    var modelContext: ModelContext?
    var currentChat: Chat?
    
    private let titleService = TitleGenerationService()
    
    init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        if currentChat == nil {
            currentChat = getOrCreateFirstChat()
        }
    }
    
    private func getOrCreateFirstChat() -> Chat {
        let fetchDescriptor = FetchDescriptor<Chat>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        do {
            let existingChats = try modelContext?.fetch(fetchDescriptor) ?? []
            if let firstChat = existingChats.first {
                return firstChat
            }
        } catch {
            print("Failed to fetch chats: \(error)")
        }
        
        // Create new chat if none exist
        let newChat = Chat()
        modelContext?.insert(newChat)
        saveContext()
        return newChat
    }
    
    func createNewChat() -> Chat {
        let newChat = Chat()
        modelContext?.insert(newChat)
        currentChat = newChat
        saveContext()
        return newChat
    }
    
    func selectChat(_ chat: Chat) {
        currentChat = chat
    }
    
    func addMessage(_ content: String, isUser: Bool) {
        guard let chat = currentChat else { return }
        
        let message = ChatMessage(content: content, isUser: isUser, chat: chat)
        // Ensure the new message is inserted into the model context before relationship mutation
        modelContext?.insert(message)
        chat.messages.append(message)
        chat.updatedAt = Date()
        
        if chat.messages.count == 2 && chat.title == "Untitled Chat" {
            Task {
                do {
                    try await generateTitleForChat(chat)
                } catch {
                    print("Title generation error: \(error)")
                }
            }
        }
        
        saveContext()
    }

    /// Deletes a specific message from the current chat.
    func deleteMessage(_ message: ChatMessage) {
        guard let chat = currentChat else { return }
        chat.messages.removeAll { $0.id == message.id }
        chat.updatedAt = Date()
        saveContext()
    }

    /// Replaces the content of an existing assistant message with a regenerated response.
    func replaceAssistantMessage(_ message: ChatMessage, with content: String) {
        guard !message.isUser else { return }
        updateMessage(message, content: content)
    }

    /// Finds the most recent user message before a given index in the current chat.
    func previousUserMessage(before message: ChatMessage) -> ChatMessage? {
        guard let chat = currentChat else { return nil }
        guard let idx = chat.messages.firstIndex(where: { $0.id == message.id }) else { return nil }
        for i in stride(from: idx - 1, through: 0, by: -1) {
            let m = chat.messages[i]
            if m.isUser { return m }
        }
        return nil
    }

    /// Finds the assistant message immediately after a given user message, if any.
    func firstAssistantAfter(userMessage: ChatMessage) -> ChatMessage? {
        guard let chat = currentChat else { return nil }
        guard let idx = chat.messages.firstIndex(where: { $0.id == userMessage.id }) else { return nil }
        guard idx + 1 < chat.messages.count else { return nil }
        let next = chat.messages[idx + 1]
        return next.isUser ? nil : next
    }

    /// Toggle pin state for a chat
    func togglePin(_ chat: Chat) {
        chat.isPinned.toggle()
        chat.updatedAt = Date()
        saveContext()
    }
    
    @MainActor
    private func generateTitleForChat(_ chat: Chat) async throws {
        guard let firstUserMessage = chat.messages.first(where: { $0.isUser })?.content else { return }
        
        let title = try await titleService.generateTitle(for: firstUserMessage)
        chat.title = title
        saveContext()
    }
    
    func deleteChat(_ chat: Chat) {
        if currentChat?.id == chat.id {
            // Find another chat to switch to
            let fetchDescriptor = FetchDescriptor<Chat>(
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            
            do {
                let allChats = try modelContext?.fetch(fetchDescriptor) ?? []
                currentChat = allChats.first { $0.id != chat.id }
            } catch {
                print("Failed to fetch chats for deletion: \(error)")
            }
            
            if currentChat == nil {
                currentChat = getOrCreateFirstChat()
            }
        }
        
        modelContext?.delete(chat)
        saveContext()
    }
    
    /// Deletes the currently selected chat, if any, and updates `currentChat` accordingly.
    func deleteCurrentChat() {
        guard let chat = currentChat else { return }
        deleteChat(chat)
    }
    
    /// Deletes all chats from the persistent store and creates a fresh empty chat.
    func deleteAllChats() {
        guard let modelContext = modelContext else { return }
        let fetchDescriptor = FetchDescriptor<Chat>()
        do {
            let allChats = try modelContext.fetch(fetchDescriptor)
            for chat in allChats {
                modelContext.delete(chat)
            }
            try modelContext.save()
        } catch {
            print("Failed to delete all chats: \(error)")
        }
        // Ensure the app has a chat to show
        currentChat = getOrCreateFirstChat()
    }
    
    /// Creates an empty assistant message placeholder in the current chat for streaming updates.
    /// - Returns: The newly created `ChatMessage` or `nil` if no current chat.
    func createAssistantPlaceholder() -> ChatMessage? {
        guard let chat = currentChat else { return nil }
        let placeholder = ChatMessage(content: "", isUser: false, chat: chat)
        chat.messages.append(placeholder)
        chat.updatedAt = Date()
        // If this is the second message in a new chat, trigger title generation
        generateTitleIfNeeded()
        saveContext()
        return placeholder
    }
    
    /// Updates the content of a message and touches the parent chat's `updatedAt`.
    func updateMessage(_ message: ChatMessage, content: String) {
        message.content = content
        message.chat?.updatedAt = Date()
        saveContext()
    }

    /// Attaches a media/document to a specific message and saves the context.
    func addAttachment(_ attachment: ChatAttachment, to message: ChatMessage) {
        // Insert attachment explicitly before linking to avoid detached model crashes
        modelContext?.insert(attachment)
        message.attachments.append(attachment)
        message.chat?.updatedAt = Date()
        saveContext()
    }

    /// Atomically creates a user message and attaches image data to it.
    /// - Parameters:
    ///   - content: The text content for the user message.
    ///   - imageDatas: Array of image `Data` to attach.
    /// - Returns: The created `ChatMessage`.
    func createUserMessageWithImages(content: String, imageDatas: [Data]) -> ChatMessage? {
        guard let chat = currentChat else { return nil }
        let message = ChatMessage(content: content, isUser: true, chat: chat)
        modelContext?.insert(message)
        chat.messages.append(message)
        for data in imageDatas {
            let att = ChatAttachment(type: .image, filename: "image.jpg", sizeBytes: data.count, message: message)
            att.thumbnailData = data
            modelContext?.insert(att)
            message.attachments.append(att)
        }
        chat.updatedAt = Date()
        saveContext()
        return message
    }

    /// Exposes a safe way to persist recent in-memory model changes (e.g., OCR updates on attachments).
    func save() {
        saveContext()
    }

    // Sentiment management removed per request (UI no longer surfaces it)

    /// Triggers title generation if the current chat has at least two messages and is still untitled.
    func generateTitleIfNeeded() {
        guard let chat = currentChat else { return }
        if chat.messages.count >= 2 && chat.title == "Untitled Chat" {
            Task {
                do {
                    try await generateTitleForChat(chat)
                } catch {
                    print("Title generation error: \(error)")
                }
            }
        }
    }
    
    private func saveContext() {
        guard let modelContext = modelContext else { return }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
