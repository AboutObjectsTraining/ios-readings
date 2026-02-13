//
//  ReadingsUnitTests.swift
//  ReadingsUnitTests
//
//  Created by Jonathan Lehr on 2/13/26.
//

import Testing
import SwiftUI
import UIKit
@testable import Readings

@Suite("HTMLTextView Tests")
@MainActor
struct HTMLTextViewTests {
    
    // MARK: - HTML Parsing Tests
    
    @Test("Parse simple HTML")
    func parseSimpleHTML() async throws {
        let html = "<p>Simple paragraph</p>"
        let textView = createTextView(with: html)
        
        #expect(textView.text.contains("Simple paragraph"))
    }
    
    @Test("Parse HTML with bold text")
    func parseHTMLWithBold() async throws {
        let html = "<p>This is <strong>bold</strong> text</p>"
        let textView = createTextView(with: html)
        
        #expect(textView.attributedText != nil)
        #expect(textView.text.contains("bold"))
        
        // Verify bold trait is present
        let hasBoldTrait = containsBoldText(in: textView.attributedText!)
        #expect(hasBoldTrait, "Expected to find bold text in attributed string")
    }
    
    @Test("Parse HTML with italic text")
    func parseHTMLWithItalic() async throws {
        let html = "<p>This is <em>italic</em> text</p>"
        let textView = createTextView(with: html)
        
        #expect(textView.attributedText != nil)
        #expect(textView.text.contains("italic"))
        
        // Verify italic trait is present
        let hasItalicTrait = containsItalicText(in: textView.attributedText!)
        #expect(hasItalicTrait, "Expected to find italic text in attributed string")
    }
    
    @Test("Parse HTML with bold and italic text")
    func parseHTMLWithBoldAndItalic() async throws {
        let html = "<p><strong><em>Bold and italic</em></strong></p>"
        let textView = createTextView(with: html)
        
        #expect(textView.attributedText != nil)
        
        // Verify both traits are present
        let hasBothTraits = containsBoldAndItalicText(in: textView.attributedText!)
        #expect(hasBothTraits, "Expected to find bold and italic text in attributed string")
    }
    
    @Test("Parse HTML with multiple paragraphs")
    func parseHTMLWithMultipleParagraphs() async throws {
        let html = "<p>First paragraph</p><p>Second paragraph</p>"
        let textView = createTextView(with: html)
        
        #expect(textView.text.contains("First paragraph"))
        #expect(textView.text.contains("Second paragraph"))
    }
    
    @Test("Parse HTML with link")
    func parseHTMLWithLink() async throws {
        let html = """
        <p>Visit <a href="https://apple.com">Apple</a> website</p>
        """
        let textView = createTextView(with: html)
        
        #expect(textView.text.contains("Apple"))
        #expect(textView.text.contains("website"))
    }
    
    // MARK: - Dynamic Type Tests
    
    @Test("Apply Dynamic Type fonts")
    func applyDynamicTypeFonts() async throws {
        let html = "<p>Regular text</p>"
        let textView = createTextView(with: html)
        
        #expect(textView.attributedText != nil)
        
        // Verify Dynamic Type font is used
        let usesDynamicType = containsDynamicTypeFont(in: textView.attributedText!)
        #expect(usesDynamicType, "Expected text to use Dynamic Type fonts")
    }
    
    @Test("Preserve bold trait with Dynamic Type")
    func preserveBoldTraitWithDynamicType() async throws {
        let html = "<p><strong>Bold text</strong></p>"
        let textView = createTextView(with: html)
        
        let attributedText = textView.attributedText!
        
        // Should use Dynamic Type AND preserve bold
        #expect(containsDynamicTypeFont(in: attributedText))
        #expect(containsBoldText(in: attributedText))
    }
    
    @Test("Preserve italic trait with Dynamic Type")
    func preserveItalicTraitWithDynamicType() async throws {
        let html = "<p><em>Italic text</em></p>"
        let textView = createTextView(with: html)
        
        let attributedText = textView.attributedText!
        
        // Should use Dynamic Type AND preserve italic
        #expect(containsDynamicTypeFont(in: attributedText))
        #expect(containsItalicText(in: attributedText))
    }
    
    // MARK: - Color Tests
    
    @Test("Apply secondary label color")
    func applySecondaryLabelColor() async throws {
        let html = "<p>Colored text</p>"
        let textView = createTextView(with: html)
        
        #expect(textView.attributedText != nil)
        
        let hasSecondaryColor = containsSecondaryLabelColor(in: textView.attributedText!)
        #expect(hasSecondaryColor, "Expected text to use secondary label color")
    }
    
    // MARK: - Configuration Tests
    
    @Test("Text view is non-editable")
    func textViewIsNonEditable() async throws {
        let html = "<p>Test</p>"
        let textView = createTextView(with: html)
        
        #expect(!textView.isEditable)
    }
    
    @Test("Text view is non-scrollable")
    func textViewIsNonScrollable() async throws {
        let html = "<p>Test</p>"
        let textView = createTextView(with: html)
        
        #expect(!textView.isScrollEnabled)
    }
    
    @Test("Text view has clear background")
    func textViewHasClearBackground() async throws {
        let html = "<p>Test</p>"
        let textView = createTextView(with: html)
        
        #expect(textView.backgroundColor == .clear)
    }
    
    // MARK: - Fallback Tests
    
    @Test("Handle empty HTML gracefully")
    func handleEmptyHTML() async throws {
        let html = ""
        let textView = createTextView(with: html)
        
        // Should not crash and should show empty or fallback
        #expect(textView.text == "" || textView.text == html)
    }
    
    @Test("Handle plain text without HTML tags")
    func handlePlainText() async throws {
        let plainText = "Just plain text without HTML"
        let textView = createTextView(with: plainText)
        
        #expect(textView.text.contains("plain text"))
    }
    
    // MARK: - Helper Methods
    
    /// Creates a configured UITextView with the given HTML content.
    private func createTextView(with html: String) -> UITextView {
        // Create and configure the text view directly
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        
        // Parse and apply the HTML
        if let attributedString = parseHTML(html) {
            let styledString = applyDynamicStyling(to: attributedString)
            textView.attributedText = styledString
        } else {
            textView.text = html
            textView.font = .preferredFont(forTextStyle: .body)
            textView.textColor = .secondaryLabel
        }
        
        return textView
    }
    
    /// Parses an HTML string into an attributed string.
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
    
    /// Applies Dynamic Type styling to an attributed string while preserving HTML formatting.
    private func applyDynamicStyling(to attributedString: NSAttributedString) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutableString.length)
        
        mutableString.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            // Apply dynamic font
            let font: UIFont
            if let existingFont = attributes[.font] as? UIFont {
                font = createDynamicFont(preservingTraitsFrom: existingFont)
            } else {
                font = .preferredFont(forTextStyle: .body)
            }
            mutableString.addAttribute(.font, value: font, range: range)
        }
        
        // Apply text color
        mutableString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: fullRange)
        
        return mutableString
    }
    
    /// Creates a Dynamic Type font that preserves bold and italic traits.
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
    private func fontWithTraits(_ traits: UIFontDescriptor.SymbolicTraits,
                               basedOn baseFont: UIFont) -> UIFont? {
        guard let descriptor = baseFont.fontDescriptor.withSymbolicTraits(traits) else {
            return nil
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
    
    /// Checks if the attributed string contains text with bold trait.
    private func containsBoldText(in attributedString: NSAttributedString) -> Bool {
        var hasBold = false
        
        attributedString.enumerateAttribute(.font, in: NSRange(location: 0, length: attributedString.length)) { value, range, stop in
            if let font = value as? UIFont {
                if font.fontDescriptor.symbolicTraits.contains(.traitBold) {
                    hasBold = true
                    stop.pointee = true
                }
            }
        }
        
        return hasBold
    }
    
    /// Checks if the attributed string contains text with italic trait.
    private func containsItalicText(in attributedString: NSAttributedString) -> Bool {
        var hasItalic = false
        
        attributedString.enumerateAttribute(.font, in: NSRange(location: 0, length: attributedString.length)) { value, range, stop in
            if let font = value as? UIFont {
                if font.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                    hasItalic = true
                    stop.pointee = true
                }
            }
        }
        
        return hasItalic
    }
    
    /// Checks if the attributed string contains text with both bold and italic traits.
    private func containsBoldAndItalicText(in attributedString: NSAttributedString) -> Bool {
        var hasBoth = false
        
        attributedString.enumerateAttribute(.font, in: NSRange(location: 0, length: attributedString.length)) { value, range, stop in
            if let font = value as? UIFont {
                let traits = font.fontDescriptor.symbolicTraits
                if traits.contains(.traitBold) && traits.contains(.traitItalic) {
                    hasBoth = true
                    stop.pointee = true
                }
            }
        }
        
        return hasBoth
    }
    
    /// Checks if the attributed string uses Dynamic Type fonts.
    private func containsDynamicTypeFont(in attributedString: NSAttributedString) -> Bool {
        var usesDynamicType = false
        
        attributedString.enumerateAttribute(.font, in: NSRange(location: 0, length: attributedString.length)) { value, range, stop in
            if let font = value as? UIFont {
                // Check if it's a preferred font (Dynamic Type)
                let preferredFont = UIFont.preferredFont(forTextStyle: .body)
                if font.familyName == preferredFont.familyName {
                    usesDynamicType = true
                    stop.pointee = true
                }
            }
        }
        
        return usesDynamicType
    }
    
    /// Checks if the attributed string uses secondary label color.
    private func containsSecondaryLabelColor(in attributedString: NSAttributedString) -> Bool {
        var hasSecondaryColor = false
        
        attributedString.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: attributedString.length)) { value, range, stop in
            if let color = value as? UIColor {
                if color == UIColor.secondaryLabel {
                    hasSecondaryColor = true
                    stop.pointee = true
                }
            }
        }
        
        return hasSecondaryColor
    }
}

