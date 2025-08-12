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
    
    var chatManager: ChatManager?
    
    private let defaultSystemPrompt: String = "You are a helpful and concise assistant. Provide clear, accurate answers in a professional manner."
    
    var session = LanguageModelSession {
        "You are a helpful and concise assistant. Provide clear, accurate answers in a professional manner."
    }

    func refreshSessionFromDefaults() {
        let prompt = UserDefaults.standard.string(forKey: "systemPrompt") ?? defaultSystemPrompt
        session = LanguageModelSession { prompt }
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
                }
                
                let prompt = Prompt(userMessage)
                let streame = session.streamResponse(to: prompt)
                
                var hasStarted = false
                var fullResponse = ""
                
                for try await promtResponse in streame {
                    if !hasStarted {
                        await MainActor.run {
                            self.isAwaitingResponse = true
                        }
                        hasStarted = true
                    }
                    fullResponse = promtResponse.content
                }
                
                await MainActor.run {
                    self.isAwaitingResponse = false
                }
                
                await MainActor.run {
                    chatManager.addMessage(fullResponse, isUser: false)
                    
                    // Haptic feedback when response is complete
                    if UserDefaults.standard.bool(forKey: "hapticsEnabled") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
                }
                
            } catch {
                print(error.localizedDescription)
                isAwaitingResponse = false
            }
        }
    }
}
