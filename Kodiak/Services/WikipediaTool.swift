import Foundation
import FoundationModels

/// A placeholder tool for future Wikipedia summarization.
/// Currently returns a friendly "coming soon" message.
struct WikipediaTool: Tool {
    let name = "wikipedia"
    let description = "Summarize topics from Wikipedia (coming soon)."

    @Generable
    struct Arguments {
        @Guide(description: "Topic or article title to summarize from Wikipedia")
        var topic: String
    }

    func call(arguments: Arguments) async throws -> String {
        return "Wikipedia tool is coming soon."
    }
}


