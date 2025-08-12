//
//  MessageView.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import SwiftUI
import FoundationModels

import UIKit

struct MessageView: View {
    let segments: [Transcript.Segment]
    let isUser: Bool
    var message: ChatMessage?
    let chatManager: ChatManager
    let model: LMModel
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showTimestamps") private var showTimestamps: Bool = true
    @State private var showEditSheet: Bool = false
    @State private var editText: String = ""
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(segments, id: \.id) { segment in
                switch segment {
                case .text(let text):
                    bubbleView(text.content)
                case .structure:
                    EmptyView()
                @unknown default:
                    EmptyView()
                }
            }
            if showTimestamps, let timestamp = message?.timestamp {
                Text(formatDate(timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
                    .padding(isUser ? .trailing : .leading, 12)
            }
            if let msg = message, !isUser {
                HStack {
                    Spacer()
                    Button {
                        model.regenerateResponse(targetAssistant: msg)
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .contextMenu { contextMenu }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                VStack {
                    TextEditor(text: $editText)
                        .frame(minHeight: 200)
                        .padding()
                }
                .navigationTitle("Edit Message")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showEditSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveEdit() }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func bubbleView(_ text: String) -> some View {
        if isUser {
            Text(text)
                .padding(10)
                .background(Color.gray.opacity(0.2), in: .rect(cornerRadius: 12))
                .frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            MarkdownTextView(text: text)
                .padding(12)
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private var contextMenu: some View {
        if let msg = message {
            Button { copyToClipboard(msg.content) } label: { Label("Copy", systemImage: "doc.on.doc") }
            if msg.isUser {
                Button { startEdit(msg) } label: { Label("Edit", systemImage: "pencil") }
                Button { model.regenerateResponse(targetUser: msg) } label: { Label("Regenerate", systemImage: "arrow.clockwise") }
            } else {
                Button { model.regenerateResponse(targetAssistant: msg) } label: { Label("Regenerate", systemImage: "arrow.clockwise") }
            }
            Divider()
            Button(role: .destructive) { deleteMessage(msg) } label: { Label("Delete", systemImage: "trash") }
            Button { shareMessage(msg) } label: { Label("Share…", systemImage: "square.and.arrow.up") }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
    
    private func startEdit(_ msg: ChatMessage) {
        editText = msg.content
        showEditSheet = true
    }
    
    private func saveEdit() {
        guard let msg = message, msg.isUser else { showEditSheet = false; return }
        chatManager.updateMessage(msg, content: editText)
        showEditSheet = false
    }
    
    private func deleteMessage(_ msg: ChatMessage) {
        chatManager.deleteMessage(msg)
    }
    
    private func shareMessage(_ msg: ChatMessage) {
        let text = msg.content
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController else { return }
        root.present(av, animated: true)
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


