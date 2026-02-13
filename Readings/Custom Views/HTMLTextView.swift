//
//  HTMLTextView.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/12/26.
//

import SwiftUI
import UIKit

/// A SwiftUI view that renders HTML content with dynamic typography and styling.
///
/// `HTMLTextView` parses HTML strings and displays them using `UITextView` with proper
/// formatting, including bold and italic text, while applying Dynamic Type for accessibility.
/// The view automatically adjusts to the proposed size and preserves HTML formatting.
///
/// Example usage:
/// ```swift
/// HTMLTextView(htmlString: "<p>This is <strong>bold</strong> text.</p>")
/// ```
struct HTMLTextView: UIViewRepresentable {
    /// The HTML content to be rendered.
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
    
    /// Configures a text view for displaying HTML content.
    ///
    /// Sets up the text view with appropriate properties for read-only HTML display,
    /// including disabling editing and scrolling, and configuring layout priorities.
    ///
    /// - Parameter textView: The text view to configure.
    /// - Returns: The configured text view.
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
    
    /// Parses an HTML string into an attributed string.
    ///
    /// Uses the system's HTML document parser to convert HTML markup into
    /// an `NSAttributedString` with appropriate formatting attributes.
    ///
    /// - Parameter html: The HTML string to parse.
    /// - Returns: An attributed string representation of the HTML, or `nil` if parsing fails.
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
    
    /// Applies Dynamic Type styling to an attributed string while preserving HTML formatting.
    ///
    /// Processes the attributed string to replace fonts with Dynamic Type equivalents
    /// while maintaining bold and italic traits from the original HTML. Also applies
    /// consistent text coloring.
    ///
    /// - Parameter attributedString: The attributed string to style.
    /// - Returns: A new attributed string with dynamic styling applied.
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
    
    /// Preserves paragraph styling from HTML formatting.
    ///
    /// Copies existing paragraph style attributes to maintain spacing and alignment
    /// from the original HTML structure.
    ///
    /// - Parameters:
    ///   - attributes: The existing attributes dictionary.
    ///   - attributedString: The mutable attributed string to modify.
    ///   - range: The range to apply the style to.
    private func applyParagraphStyle(from attributes: [NSAttributedString.Key: Any],
                                     to attributedString: NSMutableAttributedString,
                                     at range: NSRange) {
        guard let existingStyle = attributes[.paragraphStyle] as? NSParagraphStyle else { return }
        let paragraphStyle = existingStyle.mutableCopy() as! NSMutableParagraphStyle
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    }
    
    /// Applies Dynamic Type fonts while preserving HTML text traits.
    ///
    /// Replaces existing fonts with Dynamic Type equivalents, maintaining bold and
    /// italic traits from the HTML formatting.
    ///
    /// - Parameters:
    ///   - attributes: The existing attributes dictionary.
    ///   - attributedString: The mutable attributed string to modify.
    ///   - range: The range to apply the font to.
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
    
    /// Creates a Dynamic Type font that preserves bold and italic traits.
    ///
    /// Examines the symbolic traits of an existing font and creates a new Dynamic Type
    /// font with the same traits (bold, italic, or both).
    ///
    /// - Parameter existingFont: The font whose traits should be preserved.
    /// - Returns: A Dynamic Type font with matching traits.
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
    
    /// Creates a font with specified symbolic traits.
    ///
    /// - Parameters:
    ///   - traits: The symbolic traits to apply (e.g., bold, italic).
    ///   - baseFont: The base font to derive the new font from.
    /// - Returns: A font with the specified traits, or `nil` if creation fails.
    private func fontWithTraits(_ traits: UIFontDescriptor.SymbolicTraits,
                               basedOn baseFont: UIFont) -> UIFont? {
        guard let descriptor = baseFont.fontDescriptor.withSymbolicTraits(traits) else {
            return nil
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
    
    /// Applies consistent text color to the entire attributed string.
    ///
    /// - Parameters:
    ///   - attributedString: The mutable attributed string to modify.
    ///   - range: The range to apply the color to.
    private func applyTextColor(to attributedString: NSMutableAttributedString, in range: NSRange) {
        attributedString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: range)
    }
    
    // MARK: - Fallback
    
    /// Applies plain text fallback styling when HTML parsing fails.
    ///
    /// Displays the raw HTML string as plain text with basic styling when the
    /// HTML parser is unable to process the content.
    ///
    /// - Parameter textView: The text view to apply fallback styling to.
    private func applyPlainTextFallback(to textView: UITextView) {
        textView.text = htmlString
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textColor = .secondaryLabel
    }
    
    // MARK: - Layout
    
    /// Forces the text view to refresh its layout and intrinsic content size.
    ///
    /// Ensures that the text view properly calculates its size after content changes,
    /// which is necessary for correct SwiftUI layout behavior.
    ///
    /// - Parameter textView: The text view to refresh.
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
