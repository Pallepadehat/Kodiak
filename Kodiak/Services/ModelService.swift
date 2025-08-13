//
//  ModelService.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import Foundation
import FoundationModels
import SwiftUI
import CoreHaptics
import AVFoundation

@Observable
class LMModel {
    
    var inputText: String = ""
    
    var isThinking: Bool = false
    
    var isAwaitingResponse: Bool = false
    
    // Welcome suggestions for empty chat
    var welcomeSuggestions: [String] = []
    private let welcomeService = WelcomeSuggestionService()
    
    var chatManager: ChatManager?
    
    private let defaultSystemPrompt: String = "You are a helpful and concise assistant. Provide clear, accurate answers in a professional manner. You will provide good and detailed answers if the users ask for knowglage. Always respond in markdown format. ONLY USE TOOLS IF NEEDED!"
    
    var session = LanguageModelSession()
    let voice = VoiceService()
    #if os(iOS)
    let ocr = OCRService()
    #endif

    var liveTranscript: String = ""

    // Composer attachments staged before sending
    struct ComposerAttachment: Identifiable, Equatable {
        enum Kind: Equatable { case image(data: Data) }
        let id: UUID
        let kind: Kind
    }
    var composerAttachments: [ComposerAttachment] = []

    func refreshSessionFromDefaults() {
        let prompt = UserDefaults.standard.string(forKey: "systemPrompt") ?? defaultSystemPrompt
        var tools = buildEnabledTools()
        // Add image analysis tool only
        tools.append(ImageAnalysisTool())
        if tools.isEmpty {
            session = LanguageModelSession { prompt }
        } else {
            session = LanguageModelSession(tools: tools, instructions: prompt)
        }
    }

    private func buildEnabledTools() -> [any Tool] {
        var enabled: [any Tool] = []
        if UserDefaults.standard.object(forKey: "toolWeatherEnabled") == nil {
            // Default Weather ON on first launch
            UserDefaults.standard.set(true, forKey: "toolWeatherEnabled")
        }
        if UserDefaults.standard.bool(forKey: "toolWeatherEnabled") {
            enabled.append(WeatherTool())
        }
        // Future tools (disabled by default)
        if UserDefaults.standard.bool(forKey: "toolWebSearchEnabled") {
            enabled.append(WebSearchTool())
        }
        if UserDefaults.standard.bool(forKey: "toolWikipediaEnabled") {
            enabled.append(WikipediaTool())
        }
        return enabled
    }
    
    @MainActor
    func sendMessage() {
        guard !inputText.isEmpty, let chatManager = chatManager else { return }
        
        let userMessage = inputText
        inputText = ""
        
        Task { @MainActor in
            do {
                // Haptic feedback when sending message
                if UserDefaults.standard.bool(forKey: "hapticsEnabled") && CHHapticEngine.capabilitiesForHardware().supportsHaptics {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
                
                var createdMessage: ChatMessage?
                // Prepare image datas from staged attachments in the current snapshot order
                let imageDatas: [Data] = composerAttachments.compactMap { item in
                    if case .image(let data) = item.kind { return data }
                    return nil
                }
                // Create the message and bind attachments atomically to avoid mis-association
                createdMessage = chatManager.createUserMessageWithImages(content: userMessage, imageDatas: imageDatas)
                chatManager.generateTitleIfNeeded()
                // Attach staged composer attachments to the created message
                if let m = createdMessage {
                    for att in m.attachments {
                        if let data = att.thumbnailData {
                            AttachmentRegistry.shared.registerImage(data: data, for: att.id)
                        }
                    }
                }
                // Clear composer attachments after sending
                composerAttachments.removeAll()
                
                // Create a placeholder assistant message for streaming
                var placeholder: ChatMessage?
                placeholder = chatManager.createAssistantPlaceholder()
                
                // Inject contextual tool hint for latest attachments so the model knows to use tools
                var promptText = userMessage
                if AttachmentRegistry.shared.latestImageId != nil,
                   (chatManager.currentChat?.messages.last?.attachments.isEmpty == false) {
                    // Only hint when the current chat actually has attachments
                    promptText += "\n\n[Context] An image is attached in this chat. If the user refers to 'the image', use the analyzeImage tool without attachmentId to analyze the most recent image."
                }
                let prompt = Prompt(promptText)
                let stream = session.streamResponse(to: prompt)
                
                var hasStarted = false
                var fullResponse = ""
                
                for try await token in stream {
                    if !hasStarted {
                        self.isAwaitingResponse = true
                        hasStarted = true
                    }
                    fullResponse = token.content
                    if let placeholder = placeholder {
                        chatManager.updateMessage(placeholder, content: fullResponse)
                    }
                }
                
                self.isAwaitingResponse = false
                
                // Finalize placeholder and trigger haptic
                if let placeholder = placeholder {
                    chatManager.updateMessage(placeholder, content: fullResponse)
                    if UserDefaults.standard.bool(forKey: "hapticsEnabled") && CHHapticEngine.capabilitiesForHardware().supportsHaptics {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
                    if UserDefaults.standard.bool(forKey: "speakRepliesEnabled") {
                        self.voice.speak(text: fullResponse)
                    }
                }
                
                // No follow-up suggestions; welcome suggestions shown only when chat is empty
                
            } catch {
                print(error.localizedDescription)
                isAwaitingResponse = false
            }
        }
    }
    
    func loadWelcomeSuggestionsIfNeeded() {
        guard welcomeSuggestions.isEmpty else { return }
        Task {
            do {
                let suggestions = try await welcomeService.generateSuggestions()
                await MainActor.run { self.welcomeSuggestions = suggestions }
            } catch {
                // Ignore silently; UI will hide suggestions if empty
            }
        }
    }

    /// Regenerate an assistant response for a given message context.
    /// - Parameters:
    ///   - targetAssistant: If provided, we will regenerate this assistant message using the nearest preceding user message.
    ///   - targetUser: If provided, we will regenerate a response to this user message.
    func regenerateResponse(targetAssistant: ChatMessage? = nil, targetUser: ChatMessage? = nil) {
        guard let chatManager = chatManager else { return }
        Task {
            var userSource: ChatMessage?
            var assistantTarget: ChatMessage?
            if let targetUser = targetUser {
                userSource = targetUser
                assistantTarget = await MainActor.run { chatManager.firstAssistantAfter(userMessage: targetUser) }
            } else if let targetAssistant = targetAssistant {
                assistantTarget = targetAssistant
                userSource = await MainActor.run { chatManager.previousUserMessage(before: targetAssistant) }
            }
            guard let userMessage = userSource else { return }
            var promptText = userMessage.content
            if AttachmentRegistry.shared.latestImageId != nil,
               (chatManager.currentChat?.messages.last?.attachments.isEmpty == false) {
                promptText += "\n\n[Context] An image is attached in this chat. If the user refers to 'the image', use the analyzeImage tool without attachmentId to analyze the most recent image."
            }
            let prompt = Prompt(promptText)
            let stream = session.streamResponse(to: prompt)
            var fullResponse = ""
            for try await token in stream {
                fullResponse = token.content
                if let assistantTarget = assistantTarget {
                    await MainActor.run { chatManager.updateMessage(assistantTarget, content: fullResponse) }
                } else {
                    // If there was no assistant target, create/stream into a new one
                    var placeholder: ChatMessage?
                    await MainActor.run { placeholder = chatManager.createAssistantPlaceholder() }
                    if let placeholder = placeholder {
                        await MainActor.run { chatManager.updateMessage(placeholder, content: fullResponse) }
                        assistantTarget = placeholder
                    }
                }
            }
            if UserDefaults.standard.bool(forKey: "speakRepliesEnabled") {
                self.voice.speak(text: fullResponse)
            }
        }
    }

    // MARK: - Voice capture lifecycle
    func startVoiceCapture(autoSend: Bool = false) {
        #if os(iOS)
        liveTranscript = ""
        voice.startListening(onPartial: { [weak self] partial in
            self?.liveTranscript = partial
        }, onFinal: { [weak self] finalText in
            guard let self = self else { return }
            self.inputText = finalText
            if autoSend { self.sendMessage() }
            // Hands-free resume handled on TTS completion via notification observer
        }, onError: { error in
            print("Voice error: \(error.localizedDescription)")
        })
        #endif
    }
    
    func stopVoiceCapture() {
        voice.stopListening()
    }
    
    func stopSpeaking() {
        voice.stopSpeaking()
    }

    // MARK: - Hands-free loop
    init() {
        NotificationCenter.default.addObserver(forName: .voiceDidFinishSpeaking, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            if UserDefaults.standard.bool(forKey: "handsFreeEnabled") {
                self.startVoiceCapture(autoSend: true)
            }
        }
    }
}

