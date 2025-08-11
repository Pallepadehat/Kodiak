//
//  MarkdownTextView.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import SwiftUI

struct MarkdownTextView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseMarkdown(text), id: \.id) { block in
                switch block.type {
                case .text:
                    Text(block.content)
                        .textSelection(.enabled)
                case .codeBlock(let language):
                    CodeBlockView(code: block.content, language: language)
                }
            }
        }
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = text.components(separatedBy: .newlines)
        var currentBlock = ""
        var inCodeBlock = false
        var codeLanguage = ""
        
        for line in lines {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    // End of code block
                    if !currentBlock.isEmpty {
                        blocks.append(MarkdownBlock(
                            type: .codeBlock(language: codeLanguage),
                            content: currentBlock.trimmingCharacters(in: .whitespacesAndNewlines)
                        ))
                    }
                    currentBlock = ""
                    inCodeBlock = false
                    codeLanguage = ""
                } else {
                    // Start of code block
                    if !currentBlock.isEmpty {
                        blocks.append(MarkdownBlock(type: .text, content: currentBlock.trimmingCharacters(in: .whitespacesAndNewlines)))
                    }
                    currentBlock = ""
                    inCodeBlock = true
                    codeLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else {
                if inCodeBlock {
                    currentBlock += line + "\n"
                } else {
                    currentBlock += line + "\n"
                }
            }
        }
        
        // Handle remaining content
        if !currentBlock.isEmpty {
            if inCodeBlock {
                blocks.append(MarkdownBlock(
                    type: .codeBlock(language: codeLanguage),
                    content: currentBlock.trimmingCharacters(in: .whitespacesAndNewlines)
                ))
            } else {
                blocks.append(MarkdownBlock(type: .text, content: currentBlock.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
        }
        
        return blocks
    }
}

struct MarkdownBlock {
    let id = UUID()
    let type: BlockType
    let content: String
    
    enum BlockType {
        case text
        case codeBlock(language: String)
    }
}

struct CodeBlockView: View {
    let code: String
    let language: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language and copy button
            HStack {
                Text(language.isEmpty ? "Code" : language.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: copyToClipboard) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .onTapGesture {
                    copyToClipboard()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray5).opacity(0.4))
            
            // Code content
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(syntaxColor(for: language))
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .glassEffect(in: .rect)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
       
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = code
    }
    
    private func syntaxColor(for language: String) -> Color {
        switch language.lowercased() {
        case "swift":
            return .orange
        case "python":
            return .blue
        case "javascript", "js":
            return .yellow
        case "json":
            return .green
        case "html":
            return .red
        case "css":
            return .purple
        default:
            return .primary
        }
    }
}

#Preview {
    MarkdownTextView(text: """
    Here's some text before the code.
    
    ```swift
    func hello() {
        print("Hello, World!")
    }
    ```
    
    And some text after the code block.
    """)
    .padding()
}
