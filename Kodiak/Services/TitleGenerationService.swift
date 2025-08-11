//
//  TitleGenerationService.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import Foundation
import FoundationModels

@Generable
struct ChatTitle {
    let title: String
}

@Observable
class TitleGenerationService {
    private let titleSession = LanguageModelSession {
        """
        You are a title generator. Your only job is to create short, descriptive titles for conversations.
        Rules:
        - Output ONLY the title, nothing else
        - Use 2-3 words maximum
        - Be descriptive and relevant
        - No explanations or additional text
        Examples: "Weather Help", "Code Question", "Travel Planning", "Math Problem"
        """
    }
    
    func generateTitle(for conversation: String) async throws -> String {
        let prompt = Prompt("Title for: \(conversation)")
        
        let streame = titleSession.streamResponse(to: prompt)
        var fullResponse = ""
        
        for try await promtResponse in streame {
            fullResponse = promtResponse.content
        }
        
        print("Generated Title: \(fullResponse)")
        
        let cleanTitle = String(fullResponse.prefix(50)).trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanTitle
    }
}
