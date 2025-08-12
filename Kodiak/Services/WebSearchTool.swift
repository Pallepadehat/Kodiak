import Foundation
import FoundationModels

/// A placeholder tool for future web search capability.
/// Currently returns a friendly "coming soon" message.
struct WebSearchTool: Tool {
    let name = "webSearch"
    let description = "Search the web for up-to-date information (coming soon)."

    @Generable
    struct Arguments {
        @Guide(description: "The search query to look up on the web")
        var query: String
    }

    func call(arguments: Arguments) async throws -> String {
        return "Web Search is coming soon."
    }
}


