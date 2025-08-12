//
//  ModelService.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import Foundation
import FoundationModels
import SwiftUI

@Observable
class LMModel {
    
    var inputText: String = ""
    
    var isThinking: Bool = false
    
    var isAwaitingResponse: Bool = false
    
    // Welcome suggestions for empty chat
    var welcomeSuggestions: [String] = []
    private let welcomeService = WelcomeSuggestionService()
    
    var chatManager: ChatManager?
    
    private let defaultSystemPrompt: String = "You are a helpful and concise assistant. Provide clear, accurate answers in a professional manner."
    
    var session = LanguageModelSession()

    func refreshSessionFromDefaults() {
        let prompt = UserDefaults.standard.string(forKey: "systemPrompt") ?? defaultSystemPrompt
        let tools = buildEnabledTools()
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
    
    func sendMessage() {
        guard !inputText.isEmpty, let chatManager = chatManager else { return }
        
        let userMessage = inputText
        inputText = ""
        
        Task {
            do {
                // Haptic feedback when sending message
                if UserDefaults.standard.bool(forKey: "hapticsEnabled") {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
                
                await MainActor.run {
                    chatManager.addMessage(userMessage, isUser: true)
                    chatManager.generateTitleIfNeeded()
                }
                
                // Create a placeholder assistant message for streaming
                var placeholder: ChatMessage?
                await MainActor.run {
                    placeholder = chatManager.createAssistantPlaceholder()
                }
                
                let prompt = Prompt(userMessage)
                let stream = session.streamResponse(to: prompt)
                
                var hasStarted = false
                var fullResponse = ""
                
                for try await token in stream {
                    if !hasStarted {
                        await MainActor.run { self.isAwaitingResponse = true }
                        hasStarted = true
                    }
                    fullResponse = token.content
                    if let placeholder = placeholder {
                        await MainActor.run { chatManager.updateMessage(placeholder, content: fullResponse) }
                    }
                }
                
                await MainActor.run { self.isAwaitingResponse = false }
                
                // Finalize placeholder and trigger haptic
                if let placeholder = placeholder {
                    await MainActor.run {
                        chatManager.updateMessage(placeholder, content: fullResponse)
                        if UserDefaults.standard.bool(forKey: "hapticsEnabled") {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }
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
}

