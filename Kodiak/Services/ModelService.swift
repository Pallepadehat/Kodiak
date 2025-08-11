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
    
    var session = LanguageModelSession {
        """
        You are a helpful and concise assistant. Provide clear, accurate answers in a professional manner.
        """
    }
    
    func sendMessage() {
        guard !inputText.isEmpty, let chatManager = chatManager else { return }
        
        let userMessage = inputText
        inputText = ""
        
        Task {
            do {
                // Haptic feedback when sending message
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
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
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                
            } catch {
                print(error.localizedDescription)
                isAwaitingResponse = false
            }
        }
    }
}
