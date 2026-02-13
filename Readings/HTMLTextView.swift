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
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> UITextView {
        configureTextView(UITextView())
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        guard let attributedString = parseHTML(htmlString) else {
            applyPlainTextFallback(to: textView)
            return
        }
        
        let styledString = applyDynamicStyling(to: attributedString)
        textView.attributedText = styledString
        refreshLayout(for: textView)
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIView.layoutFittingExpandedSize.width
        return uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }
    
    // MARK: - Configuration
    
    private func configureTextView(_ textView: UITextView) -> UITextView {
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return textView
    }
    
    // MARK: - HTML Parsing
    
    private func parseHTML(_ html: String) -> NSAttributedString? {
        guard let data = html.data(using: .utf8) else { return nil }
        
        return try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
    }
    
    // MARK: - Styling
    
    private func applyDynamicStyling(to attributedString: NSAttributedString) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutableString.length)
        
        mutableString.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            applyParagraphStyle(from: attributes, to: mutableString, at: range)
            applyDynamicFont(from: attributes, to: mutableString, at: range)
        }
        
        applyTextColor(to: mutableString, in: fullRange)
        
        return mutableString
    }
    
    private func applyParagraphStyle(from attributes: [NSAttributedString.Key: Any],
                                     to attributedString: NSMutableAttributedString,
                                     at range: NSRange) {
        guard let existingStyle = attributes[.paragraphStyle] as? NSParagraphStyle else { return }
        let paragraphStyle = existingStyle.mutableCopy() as! NSMutableParagraphStyle
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    }
    
    private func applyDynamicFont(from attributes: [NSAttributedString.Key: Any],
                                  to attributedString: NSMutableAttributedString,
                                  at range: NSRange) {
        let font: UIFont
        
        if let existingFont = attributes[.font] as? UIFont {
            font = createDynamicFont(preservingTraitsFrom: existingFont)
        } else {
            font = .preferredFont(forTextStyle: .body)
        }
        
        attributedString.addAttribute(.font, value: font, range: range)
    }
    
    private func createDynamicFont(preservingTraitsFrom existingFont: UIFont) -> UIFont {
        let traits = existingFont.fontDescriptor.symbolicTraits
        let baseFont = UIFont.preferredFont(forTextStyle: .body)
        
        // Map traits to the appropriate font
        switch traits {
        case let t where t.contains([.traitBold, .traitItalic]):
            return fontWithTraits([.traitBold, .traitItalic], basedOn: baseFont) ?? baseFont
        case let t where t.contains(.traitBold):
            return fontWithTraits(.traitBold, basedOn: baseFont) ?? baseFont
        case let t where t.contains(.traitItalic):
            return fontWithTraits(.traitItalic, basedOn: baseFont) ?? baseFont
        default:
            return baseFont
        }
    }
    
    private func fontWithTraits(_ traits: UIFontDescriptor.SymbolicTraits,
                               basedOn baseFont: UIFont) -> UIFont? {
        guard let descriptor = baseFont.fontDescriptor.withSymbolicTraits(traits) else {
            return nil
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
    
    private func applyTextColor(to attributedString: NSMutableAttributedString, in range: NSRange) {
        attributedString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: range)
    }
    
    // MARK: - Fallback
    
    private func applyPlainTextFallback(to textView: UITextView) {
        textView.text = htmlString
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textColor = .secondaryLabel
    }
    
    // MARK: - Layout
    
    private func refreshLayout(for textView: UITextView) {
        textView.setNeedsLayout()
        textView.layoutIfNeeded()
        
        DispatchQueue.main.async {
            textView.invalidateIntrinsicContentSize()
        }
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
