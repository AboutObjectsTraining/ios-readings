//
//  MarkdownTextView.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/13/26.
//

import SwiftUI

struct MarkdownTextView: View {
    let markdownText: String
    
    var body: some View {
        if let attributedString = try? AttributedString(markdown: markdownText) {
            Text(attributedString)
                .font(.body)
                .foregroundStyle(.secondary)
        } else {
            // Fallback to plain text if markdown parsing fails
            Text(markdownText)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        MarkdownTextView(markdownText: """
            This is a **bold** statement with *italic* text.
            
            It also supports `code` and [links](https://apple.com).
            """)
        .padding()
    }
}
