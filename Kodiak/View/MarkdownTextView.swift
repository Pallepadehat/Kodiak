//
//  MarkdownTextView.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import SwiftUI
import MarkdownUI

struct MarkdownTextView: View {
    let text: String
    
    var body: some View {
        Markdown(text)
            .markdownTheme(.kodiak)
    }
}

// MARK: - Kodiak Markdown Theme
private extension Theme {
    static let kodiak: Theme = Theme()
        // Inline code style
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.9))
            BackgroundColor(Color.orange.opacity(0.12))
            ForegroundColor(.primary)
        }
        .link {
            ForegroundColor(.orange)
            UnderlineStyle(.single)
        }
        // Headings
        .heading1 { configuration in
            configuration.label
                .font(.system(size: 22, weight: .semibold))
                .markdownMargin(top: 8, bottom: 8)
        }
        .heading2 { configuration in
            configuration.label
                .font(.system(size: 20, weight: .semibold))
                .markdownMargin(top: 8, bottom: 6)
        }
        .heading3 { configuration in
            configuration.label
                .font(.system(size: 18, weight: .semibold))
                .markdownMargin(top: 6, bottom: 6)
        }
        // Paragraphs & lists
        .paragraph { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.25))
                .markdownMargin(top: 0, bottom: 8)
        }
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: .em(0.15))
        }
        // Blockquote
        .blockquote { configuration in
            configuration.label
                .markdownTextStyle {
                    ForegroundColor(.primary)
                }
                .padding(.init(top: 10, leading: 10, bottom: 10, trailing: 10))
                .overlay(alignment: .leading) {
                    Rectangle().fill(Color.orange.opacity(0.6)).frame(width: 3)
                }
                .background(Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        // Code blocks
        .codeBlock { configuration in
            configuration.label
                .markdownTextStyle {
                    FontFamilyVariant(.monospaced)
                }
                .padding(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        // Tables
        .table { configuration in
            configuration.label
                .background(Color.clear)
        }
        .tableCell { configuration in
            configuration.label
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color(.systemBackground).opacity(0.6))
                .overlay(Rectangle().stroke(Color.secondary.opacity(0.15), lineWidth: 0.5))
        }
}

#Preview {
    MarkdownTextView(text: """
    ## Hello World
    
    Render Markdown text in SwiftUI.
    """)
    .padding()
}
