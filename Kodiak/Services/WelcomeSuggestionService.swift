//
//  WelcomeSuggestionService.swift
//  Kodiak
//
//  Created by Assistant on 12/08/2025.
//

import Foundation
import FoundationModels

@Generable(description: "A compact set of short starter suggestions to begin a chat")
struct WelcomeSuggestions {
    var suggestion1: String
    var suggestion2: String
    var suggestion3: String
    var suggestion4: String
    var suggestion5: String
    var suggestion6: String
}

final class WelcomeSuggestionService {
    private let session = LanguageModelSession {
        """
        You are a helpful product assistant. Generate short, safe, actionable starter prompts for an AI chat app.
        Each suggestion should be concise and suitable for a general audience.
        """
    }
    
    func generateSuggestions() async throws -> [String] {
        let prompt = Prompt(
            """
            Create six short and diverse starter prompts to begin a conversation in an AI assistant app for the user.
            That could be like a math problem like: What is 2+2
            It could also be a queistion like: Who was the president of USA under ww2
            Requirements:
            - 2 to 5 words each
            - No punctuation at the end
            - Broadly useful (learning, coding, planning, writing, explaining)
            - Avoid sensitive content
            """
        )

        // Use Generable structured output to get a typed result directly
        let response = try await session.respond(
            to: prompt,
            generating: WelcomeSuggestions.self
        )
        let suggestions = response.content
        return [
            suggestions.suggestion1,
            suggestions.suggestion2,
            suggestions.suggestion3,
            suggestions.suggestion4,
            suggestions.suggestion5,
            suggestions.suggestion6
        ]
        .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    }
}


