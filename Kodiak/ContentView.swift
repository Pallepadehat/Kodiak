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
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("animateTitle") private var animateTitle: Bool = true
    @AppStorage("titleTypeSpeed") private var titleTypeSpeed: Double = 0.05
    @AppStorage("systemPrompt") private var systemPrompt: String = "You are a helpful and concise assistant. Provide clear, accurate answers in a professional manner."
    @State private var displayedTitle = ""
    @State private var fullGeneratedTitle = ""
    @State private var isTypingTitle = false
    @State private var showToolsSheet = false
    
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
    
    var welcomeView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 56))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.orange, .orange.opacity(0.5))
                Text("Welcome to Kodiak")
                    .font(.largeTitle.bold())
                Text("Your personal AI chat. Ask questions, learn new things, plan, write, and build.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if !model.welcomeSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(model.welcomeSuggestions, id: \.self) { suggestion in
                            Button {
                                model.inputText = suggestion
                                model.sendMessage()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                    Text(suggestion)
                                }
                                .font(.callout)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal)
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if let currentChat = chatManager.currentChat {
                        ForEach(currentChat.messages.sorted(by: { $0.timestamp < $1.timestamp }), id: \.id) { message in
                            VStack(alignment: .leading, spacing: 6) {
                                MessageView(
                                    segments: [Transcript.Segment.text(Transcript.TextSegment(content: message.content))],
                                    isUser: message.isUser
                                )
                                .padding(message.isUser ? .trailing : .leading, message.isUser ? 0 : 10)

                                // Sentiment UI removed per request
                            }
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
                .onChange(of: model.isAwaitingResponse) { 
                    if model.isAwaitingResponse {
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
        HStack(spacing: 8) {
            // Tool tag pill
            if UserDefaults.standard.bool(forKey: "toolWebSearchEnabled") {
                Label("Search", systemImage: "globe")
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.1), in: Capsule())
            }
            
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

            // Plus button to open tools sheet
            Button {
                showToolsSheet = true
            } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: 28, weight: .semibold))
            }
            .disabled(model.session.isResponding)

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
                
                if (chatManager.currentChat?.messages.isEmpty ?? true) {
                    welcomeView
                        .transition(.opacity)
                } else {
                    chatScrollView
                }
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
        .sheet(isPresented: $showToolsSheet) {
            ToolsSheetView(onPreferencesChanged: {
                model.refreshSessionFromDefaults()
            })
            .presentationDetents([.fraction(0.5)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(chatManager: $chatManager)
        }
        .onAppear {
            chatManager.setModelContext(modelContext)
            model.chatManager = chatManager
            model.refreshSessionFromDefaults()
            model.loadWelcomeSuggestionsIfNeeded()
        }
        .onChange(of: chatManager.currentChat?.title) { newTitle in
            if let title = newTitle, title != "Untitled Chat" {
                // Start typewriter animation when new title is generated
                fullGeneratedTitle = title
                startTypewriterAnimation()
            }
        }
        .onChange(of: systemPrompt) { _ in
            model.refreshSessionFromDefaults()
        }
    }
    
    private func startTypewriterAnimation() {
        guard animateTitle else { return }
        displayedTitle = ""
        isTypingTitle = true
        
        // Light haptic when starting to type
        if hapticsEnabled {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        // Type out each character with a delay
        for (index, character) in fullGeneratedTitle.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * max(0.02, min(0.12, titleTypeSpeed))) {
                displayedTitle += String(character)
                
                // Small haptic for each character (very subtle)
                if hapticsEnabled {
                    if index % 3 == 0 {  // Only every 3rd character to avoid overwhelming
                        let subtleFeedback = UIImpactFeedbackGenerator(style: .rigid)
                        subtleFeedback.impactOccurred(intensity: 0.3)
                    }
                }
                
                // When finished typing
                if index == fullGeneratedTitle.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isTypingTitle = false
                        
                        // Final haptic when complete
                        if hapticsEnabled {
                            let completeFeedback = UIImpactFeedbackGenerator(style: .medium)
                            completeFeedback.impactOccurred()
                        }
                    }
                }
            }
        }
    }

    // Export removed per request
}

#Preview {
    ContentView()
}
