//
//  ChatHistorySheet.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import SwiftUI
import SwiftData

struct ChatHistorySheet: View {
    @Binding var chatManager: ChatManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Use @Query for automatic updates and proper sorting
    @Query(sort: [SortDescriptor(\Chat.updatedAt, order: .reverse)]) 
    var chats: [Chat]
    
    init(chatManager: Binding<ChatManager>) {
        self._chatManager = chatManager
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(chats, id: \.id) { chat in
                    Button {
                        chatManager.selectChat(chat)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(chat.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                
                                Text("\(chat.messages.count) messages • \(formatDate(chat.updatedAt))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if chatManager.currentChat?.id == chat.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.orange)
                                    .font(.headline)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteChats)
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        createNewChat()
                        dismiss()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func createNewChat() {
        let newChat = Chat()
        modelContext.insert(newChat)
        chatManager.currentChat = newChat
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to create new chat: \(error)")
        }
    }
    
    private func deleteChats(offsets: IndexSet) {
        for index in offsets {
            let chat = chats[index]
            
            // Update current chat if we're deleting it
            if chatManager.currentChat?.id == chat.id {
                chatManager.currentChat = chats.first { $0.id != chat.id }
                if chatManager.currentChat == nil && chats.count > 1 {
                    chatManager.currentChat = chats[chats.count > index + 1 ? index + 1 : 0]
                }
            }
            
            modelContext.delete(chat)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete chats: \(error)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEE"
        } else {
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: date)
    }
}