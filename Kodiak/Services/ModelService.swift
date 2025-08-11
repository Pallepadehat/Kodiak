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
    
    var session = LanguageModelSession {
        """
        You are a helpful and concise assistant. Provide clear, accurate answers in a professional manner.
        """
    }
    
    func sendMessage() {
        
        Task {
            do {
                
                let prompt = Prompt(inputText)
                
                inputText = ""
                
                let streame = session.streamResponse(to: prompt)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isAwaitingResponse = true
                }
                
                for try await promtResponse in streame {
                    isAwaitingResponse = false
                    print(promtResponse)
                }
                
                
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
