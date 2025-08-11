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
    
    private func saveContext() {
        guard let modelContext = modelContext else { return }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
