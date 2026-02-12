//
//  HTMLTextView.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/12/26.
//

import SwiftUI
import UIKit

struct HTMLTextView: UIViewRepresentable {
    let htmlString: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        // Convert HTML string to attributed string
        if let data = htmlString.data(using: .utf8) {
            do {
                let attributedString = try NSAttributedString(
                    data: data,
                    options: [
                        .documentType: NSAttributedString.DocumentType.html,
                        .characterEncoding: String.Encoding.utf8.rawValue
                    ],
                    documentAttributes: nil
                )
                
                // Apply dynamic font sizing
                let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
                let fullRange = NSRange(location: 0, length: mutableAttributedString.length)
                
                // Set font and color
                mutableAttributedString.addAttribute(
                    .font,
                    value: UIFont.preferredFont(forTextStyle: .body),
                    range: fullRange
                )
                mutableAttributedString.addAttribute(
                    .foregroundColor,
                    value: UIColor.secondaryLabel,
                    range: fullRange
                )
                
                textView.attributedText = mutableAttributedString
                
                // Force layout update
                textView.setNeedsLayout()
                textView.layoutIfNeeded()
                
                // Invalidate the intrinsic content size
                DispatchQueue.main.async {
                    textView.invalidateIntrinsicContentSize()
                }
            } catch {
                // Fallback to plain text if HTML parsing fails
                textView.text = htmlString
                textView.font = .preferredFont(forTextStyle: .body)
                textView.textColor = .secondaryLabel
            }
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIView.layoutFittingExpandedSize.width
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return size
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Text("HTML Preview")
                .font(.headline)
            
            HTMLTextView(htmlString: """
                <p>This is a <strong>bold</strong> test with <em>italic</em> text.</p>
                <p>It also supports <a href="https://apple.com">links</a> and line breaks.</p>
                """)
        }
        .padding()
    }
}
