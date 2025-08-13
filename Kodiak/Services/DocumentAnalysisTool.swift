//
//  DocumentAnalysisTool.swift
//  Kodiak
//
//  Created by Assistant on 13/08/2025.
//

import Foundation
import FoundationModels

struct DocumentAnalysisTool: Tool {
    let name = "analyzeDocument"
    let description = "Analyze extracted document text to summarize and extract key information."

    @Generable
    struct Arguments {
        @Guide(description: "The OCR-extracted text content of the document")
        var text: String
        @Guide(description: "Optional metadata like filename and type")
        var metadata: String?
    }

    func call(arguments: Arguments) async throws -> String {
        let text = arguments.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "No document text provided." }
        let prompt = Prompt(
            """
            You are given text extracted from a user-provided document. Produce:
            - A concise summary
            - 5 key bullet points
            - Important entities (names, dates, amounts)
            - If multi-page, a rough table of contents with page ranges
            Keep it structured and readable.
            Document metadata: \(arguments.metadata ?? "none")
            Document text:
            \(text.prefix(8000))
            """
        )
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)
        return response.content
    }
}


