//
//  ContentView.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import CoreHaptics
import FoundationModels
import SwiftData
import SwiftUI
import UIKit

#if os(iOS)
    // PDF removed
#endif

struct ContentView: View {
    @State var model = LMModel()
    @State var chatManager = ChatManager()
    @State private var showSidebar = false
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingSettings = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("animateTitle") private var animateTitle: Bool = true
    @AppStorage("titleTypeSpeed") private var titleTypeSpeed: Double = 0.05
    @AppStorage("systemPrompt") private var systemPrompt: String =
        "You are a helpful and concise assistant. Provide clear, accurate answers in a professional manner."
    @State private var displayedTitle = ""
    @State private var fullGeneratedTitle = ""
    @State private var isTypingTitle = false
    @State private var showToolsSheet = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    // PDF picker removed
    @State private var isRecording = false
    @AppStorage("voiceInputEnabled") private var voiceInputEnabled: Bool = false
    @AppStorage("handsFreeEnabled") private var handsFreeEnabled: Bool = false

    var sidebarOverlay: some View {
        EmptyView()
    }

    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.orange.opacity(0.4),
                Color.yellow.opacity(0.2),
                Color(.systemBackground).opacity(1),
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
                Text(
                    "Your personal AI chat. Ask questions, learn new things, plan, write, and build."
                )
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }

            if !model.welcomeSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(model.welcomeSuggestions, id: \.self) {
                            suggestion in
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
                        ForEach(
                            currentChat.messages.sorted(by: {
                                $0.timestamp < $1.timestamp
                            }),
                            id: \.id
                        ) { message in
                            VStack(alignment: .leading, spacing: 6) {
                                MessageView(
                                    segments: [
                                        Transcript.Segment.text(
                                            Transcript.TextSegment(
                                                content: message.content
                                            )
                                        )
                                    ],
                                    isUser: message.isUser,
                                    message: message,
                                    chatManager: chatManager,
                                    model: model
                                )
                                .padding(
                                    message.isUser ? .trailing : .leading,
                                    message.isUser ? 0 : 10
                                )

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
                .animation(
                    .easeInOut,
                    value: chatManager.currentChat?.messages.count
                )
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
        VStack(spacing: 8) {
            // Composer attachment previews
            if !model.composerAttachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(model.composerAttachments) { item in
                            ZStack(alignment: .topTrailing) {
                                #if os(iOS)
                                    switch item.kind {
                                    case .image(let data):
                                        if let ui = UIImage(data: data) {
                                            Image(uiImage: ui)
                                                .resizable()
                                                .aspectRatio(
                                                    1,
                                                    contentMode: .fill
                                                )
                                                .frame(width: 120, height: 120)
                                                .clipShape(
                                                    .rect(cornerRadius: 16)
                                                )
                                        }
                                    
                                    }
                                #endif
                                Button {
                                    if let idx = model.composerAttachments
                                        .firstIndex(where: { $0.id == item.id })
                                    {
                                        model.composerAttachments.remove(
                                            at: idx
                                        )
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(.white)
                                        .shadow(radius: 2)
                                }
                                .offset(x: -6, y: 6)
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                }
            }

            // Text input row + actions
            HStack(spacing: 10) {
                // Attach

                TextField(
                    "Ask Anything",
                    text: $model.inputText,
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .disabled(model.session.isResponding)
                .frame(height: 44)
                .onSubmit {
                    if !model.inputText.isEmpty && !model.session.isResponding {
                        model.sendMessage()
                    }
                }

                Menu {
                    Button { showPhotoPicker = true } label: { Label("Photo Library", systemImage: "photo.on.rectangle") }
                    Button { showCamera = true } label: { Label("Camera", systemImage: "camera") }
                    Button { showToolsSheet.toggle() } label: { Label("AI Tools", systemImage: "apple.writing.tools") }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                }
                .disabled(model.session.isResponding)

                // Mic
                Button {
                    if isRecording {
                        model.stopVoiceCapture()
                        isRecording = false
                    } else {
                        model.startVoiceCapture(autoSend: handsFreeEnabled)
                        isRecording = true
                    }
                } label: {
                    Image(systemName: isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            voiceInputEnabled ? Color.primary : Color.gray
                        )
                }
                .disabled(
                    !voiceInputEnabled || model.session.isResponding
                )

                Button {
                    model.sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(
                            model.session.isResponding
                                ? Color.gray.opacity(0.6) : .primary
                        )
                }
                .disabled(
                    (model.inputText.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty && model.composerAttachments.isEmpty)
                        || model.session.isResponding
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .glassEffect()
        }
        .padding(.horizontal)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.vertical)
        .sheet(isPresented: $showPhotoPicker) {
            ImagePicker { image in
                handlePickedImage(image)
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(sourceType: .camera) { image in
                handlePickedImage(image)
            }
        }
        // PDF picker removed
    }

    var body: some View {
        NavigationStack {
            ZStack {
                sidebarOverlay
                backgroundGradient

                if chatManager.currentChat?.messages.isEmpty ?? true {
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
                    Menu {
                        Button {
                            promptRenameTitle()
                        } label: {
                            Label("Rename Chat", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            if let current = chatManager.currentChat {
                                chatManager.deleteChat(current)
                            }
                        } label: {
                            Label("Delete Chat", systemImage: "trash")
                        }
                        Button {
                            shareCurrentChat()
                        } label: {
                            Label(
                                "Share Chat",
                                systemImage: "square.and.arrow.up"
                            )
                        }
                        Divider()
                        Button {
                            isShowingSettings.toggle()
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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

    // MARK: - Attachments handling (composer staging)
    private func handlePickedImage(_ image: UIImage?) {
        guard let image = image else { return }
        if let data = image.jpegData(compressionQuality: 0.85) {
            model.composerAttachments.append(
                LMModel.ComposerAttachment(id: UUID(), kind: .image(data: data))
            )
        }
    }

    // PDF handler removed

    private func startTypewriterAnimation() {
        guard animateTitle else { return }
        displayedTitle = ""
        isTypingTitle = true

        // Light haptic when starting to type (only on iOS devices with haptics)
        #if os(iOS)
            if hapticsEnabled && deviceSupportsHaptics {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        #endif

        // Type out each character with a delay
        for (index, character) in fullGeneratedTitle.enumerated() {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Double(index)
                    * max(0.02, min(0.12, titleTypeSpeed))
            ) {
                displayedTitle += String(character)

                // Small haptic for each character (very subtle)
                #if os(iOS)
                    if hapticsEnabled && deviceSupportsHaptics {
                        if index % 3 == 0 {  // Only every 3rd character to avoid overwhelming
                            let subtleFeedback = UIImpactFeedbackGenerator(
                                style: .rigid
                            )
                            subtleFeedback.impactOccurred(intensity: 0.3)
                        }
                    }
                #endif

                // When finished typing
                if index == fullGeneratedTitle.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isTypingTitle = false

                        // Final haptic when complete
                        #if os(iOS)
                            if hapticsEnabled && deviceSupportsHaptics {
                                let completeFeedback =
                                    UIImpactFeedbackGenerator(style: .medium)
                                completeFeedback.impactOccurred()
                            }
                        #endif
                    }
                }
            }
        }
    }

    // Export removed per request

    #if os(iOS)
        private var deviceSupportsHaptics: Bool {
            CHHapticEngine.capabilitiesForHardware().supportsHaptics
        }
    #endif
    private func promptRenameTitle() {
        guard let current = chatManager.currentChat else { return }
        let alert = UIAlertController(
            title: "Rename Chat",
            message: nil,
            preferredStyle: .alert
        )
        alert.addTextField { tf in tf.text = current.title }
        alert.addAction(
            UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        )
        alert.addAction(
            UIAlertAction(
                title: "Save",
                style: .default,
                handler: { _ in
                    if let text = alert.textFields?.first?.text,
                        !text.trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    {
                        current.title = String(text.prefix(50))
                        chatManager.generateTitleIfNeeded()
                    }
                }
            )
        )
        presentAlert(alert)
    }

    private func presentAlert(_ alert: UIAlertController) {
        guard
            let scene = UIApplication.shared.connectedScenes.first
                as? UIWindowScene,
            let root = scene.keyWindow?.rootViewController
        else { return }
        root.present(alert, animated: true)
    }

    private func shareCurrentChat() {
        guard let chat = chatManager.currentChat, !chat.messages.isEmpty else {
            return
        }
        let text = buildMarkdown(for: chat)
        let av = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        guard
            let scene = UIApplication.shared.connectedScenes.first
                as? UIWindowScene,
            let root = scene.keyWindow?.rootViewController
        else { return }
        root.present(av, animated: true)
    }

    private func buildMarkdown(for chat: Chat) -> String {
        var lines: [String] = ["# \(chat.title)"]
        for m in chat.messages.sorted(by: { $0.timestamp < $1.timestamp }) {
            lines.append(
                "\(m.isUser ? "**You**" : "**Kodiak**"): \n\(m.content)\n"
            )
        }
        return lines.joined(separator: "\n\n")
    }
}

#Preview {
    ContentView()
}
