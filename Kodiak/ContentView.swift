//
//  ContentView.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import FoundationModels
import SwiftUI
import SwiftData

struct ContentView: View {
    @State var model = LMModel()
    @State var chatManager = ChatManager()
    @State private var showSidebar = false
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingSettings = false
    @State private var displayedTitle = ""
    @State private var fullGeneratedTitle = ""
    @State private var isTypingTitle = false
    
    var sidebarOverlay: some View {
        EmptyView()
    }
    
    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.orange.opacity(0.4),
                Color.yellow.opacity(0.2),
                Color(.systemBackground).opacity(1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if let currentChat = chatManager.currentChat {
                        ForEach(currentChat.messages.sorted(by: { $0.timestamp < $1.timestamp }), id: \.id) { message in
                            MessageView(
                                segments: [Transcript.Segment.text(Transcript.TextSegment(content: message.content))],
                                isUser: message.isUser
                            )
                            .padding(message.isUser ? .trailing : .leading, message.isUser ? 0 : 10)
                        }
                    }

                    if model.isAwaitingResponse {
                        HStack {
                            Text("Thinking...")
                                .bold()
                                .opacity(model.isThinking ? 0.5 : 1)
                                .onAppear {
                                    withAnimation(
                                        .linear(duration: 1).repeatForever(
                                            autoreverses: true
                                        )
                                    ) {
                                        model.isThinking.toggle()
                                    }
                                }
                            Spacer()
                        }
                        .padding(.leading, 10)
                        .id("thinking")
                    }
                    
                    // Bottom spacer to ensure proper padding
                    Spacer()
                        .frame(height: 120)
                        .id("bottom")
                }
                .padding(.horizontal, 10)
                .animation(.easeInOut, value: chatManager.currentChat?.messages.count)
                .onChange(of: chatManager.currentChat?.messages.count) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: model.isAwaitingResponse) { isWaiting in
                    if isWaiting {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("thinking", anchor: .bottom)
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    // Auto-scroll to bottom when view appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
        }
    }
    
    var titleWithAnimation: String {
        let baseTitle = chatManager.currentChat?.title ?? "Untitled Chat"
        
        // If we're typing out the title, show the partial version with cursor
        if isTypingTitle {
            return displayedTitle + "|"
        }
        
        return baseTitle
    }
    
    var inputSection: some View {
        HStack {
            TextField(
                "Ask me anything...",
                text: $model.inputText,
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .disabled(model.session.isResponding)
            .frame(height: 55)
            .onSubmit {
                if !model.inputText.isEmpty && !model.session.isResponding {
                    model.sendMessage()
                }
            }

            Button {
                model.sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(
                        model.session.isResponding
                            ? Color.gray.opacity(0.6) : .primary
                    )
            }
            .disabled(
                model.inputText.isEmpty || model.session.isResponding
            )
        }
        .padding(.horizontal)
        .glassEffect(.regular.interactive())
        .padding()
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                sidebarOverlay
                backgroundGradient
                
                chatScrollView
                inputSection
            }
            .navigationTitle(titleWithAnimation)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSidebar = true
                    } label: {
                        Image(systemName: "sidebar.left")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let _ = chatManager.createNewChat()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    
                    Button {
                        let _ = chatManager.createNewChat()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings.toggle()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .sheet(isPresented: $showSidebar) {
            ChatHistorySheet(chatManager: $chatManager)
        }
        .sheet(isPresented: $isShowingSettings) {
            // TODO: ADD sheet
        }
        .onAppear {
            chatManager.setModelContext(modelContext)
            model.chatManager = chatManager
        }
        .onChange(of: chatManager.currentChat?.title) { newTitle in
            if let title = newTitle, title != "Untitled Chat" {
                // Start typewriter animation when new title is generated
                fullGeneratedTitle = title
                startTypewriterAnimation()
            }
        }
    }
    
    private func startTypewriterAnimation() {
        displayedTitle = ""
        isTypingTitle = true
        
        // Light haptic when starting to type
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Type out each character with a delay
        for (index, character) in fullGeneratedTitle.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                displayedTitle += String(character)
                
                // Small haptic for each character (very subtle)
                if index % 3 == 0 {  // Only every 3rd character to avoid overwhelming
                    let subtleFeedback = UIImpactFeedbackGenerator(style: .rigid)
                    subtleFeedback.impactOccurred(intensity: 0.3)
                }
                
                // When finished typing
                if index == fullGeneratedTitle.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isTypingTitle = false
                        
                        // Final haptic when complete
                        let completeFeedback = UIImpactFeedbackGenerator(style: .medium)
                        completeFeedback.impactOccurred()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
