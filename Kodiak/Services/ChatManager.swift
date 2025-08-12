//
//  ChatManager.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import Foundation
import SwiftData
import SwiftUI

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

    /// Sets a simple sentiment label on a message and persists it.
    func setSentiment(for message: ChatMessage, sentiment: String?) {
        message.sentiment = sentiment
        message.chat?.updatedAt = Date()
        saveContext()
    }

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
