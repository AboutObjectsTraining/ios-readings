//
//  BookReviewService.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/13/26.
//

import Foundation
import FoundationModels

@Observable
class BookReviewService {
    private var model = SystemLanguageModel.default
    private var session: LanguageModelSession?
    
    var isGenerating = false
    var generatedReview: String?
    var modelAvailability: SystemLanguageModel.Availability {
        model.availability
    }
    
    func generateReview(for book: Book) async throws {
        guard case .available = model.availability else {
            throw ReviewError.modelUnavailable
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        // Create a session with instructions for book reviews
        let instructions = """
        You are a knowledgeable book critic who writes brief, insightful reviews.
        Provide a balanced review that highlights both strengths and potential considerations.
        Keep the review concise (2-3 sentences) and engaging.
        Focus on the book's themes, writing style, and appeal to readers.
        """
        
        session = LanguageModelSession(instructions: instructions)
        
        // Create a prompt with book details
        let prompt = """
        Write a brief review for the book:
        Title: \(book.title)
        Author: \(book.author)
        \(book.description != nil ? "Description: \(book.description!)" : "")
        """
        
        // Generate the review
        let response = try await session!.respond(to: prompt)
        generatedReview = response.content
    }
    
    func clearReview() {
        generatedReview = nil
        session = nil
    }
    
    enum ReviewError: LocalizedError {
        case modelUnavailable
        
        var errorDescription: String? {
            switch self {
            case .modelUnavailable:
                return "The language model is not available on this device."
            }
        }
    }
}
