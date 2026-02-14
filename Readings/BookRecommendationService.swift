//
//  BookRecommendationService.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/13/26.
//

import Foundation
import FoundationModels

/// A service that provides AI-powered book recommendations based on a user's reading list.
///
/// `BookRecommendationService` analyzes the user's existing books using on-device
/// language models to generate personalized reading recommendations with explanations.
@Observable
class BookRecommendationService {
    
    // MARK: - Properties
    
    private var model = SystemLanguageModel.default
    private var analysisSession: LanguageModelSession?
    private var recommendationSession: LanguageModelSession?
    
    var isAnalyzing = false
    var recommendations: [Recommendation] = []
    var readingProfile: ReadingProfile?
    var error: RecommendationError?
    
    var modelAvailability: SystemLanguageModel.Availability {
        model.availability
    }
    
    // MARK: - Types
    
    struct Recommendation: Identifiable, Codable {
        let id: UUID
        let bookTitle: String
        let author: String
        let genre: String
        let themes: [String]
        let reasoning: String
        let searchQuery: String
        let confidence: ConfidenceLevel
        
        init(bookTitle: String, author: String, genre: String, themes: [String], reasoning: String, searchQuery: String, confidence: ConfidenceLevel) {
            self.id = UUID()
            self.bookTitle = bookTitle
            self.author = author
            self.genre = genre
            self.themes = themes
            self.reasoning = reasoning
            self.searchQuery = searchQuery
            self.confidence = confidence
        }
        
        enum ConfidenceLevel: String, Codable {
            case high = "High"
            case medium = "Medium"
            case low = "Low"
            
            var icon: String {
                switch self {
                case .high: return "star.fill"
                case .medium: return "star.leadinghalf.filled"
                case .low: return "star"
                }
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case id, bookTitle, author, genre, themes, reasoning, searchQuery, confidence
        }
    }
    
    struct ReadingProfile: Codable {
        let genres: [String]
        let themes: [String]
        let authorStyles: [String]
        let preferredSubjects: [String]
        let summary: String
    }
    
    // Internal structured response models
    @Generable
    fileprivate struct ProfileResponse: Codable {
        let genres: [String]
        let themes: [String]
        let authorStyles: [String]
        let subjects: [String]
        let summary: String
    }
    
    @Generable
    fileprivate struct RecommendationsResponse: Codable {
        let recommendations: [RecommendationItem]
        
        @Generable
        struct RecommendationItem: Codable {
            let title: String
            let author: String
            let genre: String
            let themes: [String]
            let reasoning: String
            let searchQuery: String
            let confidence: String
        }
    }
    
    enum RecommendationError: LocalizedError {
        case modelUnavailable
        case insufficientData
        case analysisFailed
        
        var errorDescription: String {
            switch self {
            case .modelUnavailable:
                return "AI model is not available on this device."
            case .insufficientData:
                return "Add at least 2 books to get personalized recommendations."
            case .analysisFailed:
                return "Failed to analyze your reading preferences. Please try again."
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Analyzes the user's reading list and generates personalized recommendations.
    func generateRecommendations(for books: [Book]) async throws {
        guard case .available = model.availability else {
            throw RecommendationError.modelUnavailable
        }
        
        guard books.count >= 2 else {
            throw RecommendationError.insufficientData
        }
        
        isAnalyzing = true
        error = nil
        recommendations = []
        readingProfile = nil
        
        defer {
            isAnalyzing = false
        }
        
        do {
            // Step 1: Analyze reading profile
            let profile = try await analyzeReadingList(books)
            readingProfile = profile
            print("✅ Profile: \(profile.genres.joined(separator: ", "))")
            
            // Step 2: Generate recommendations
            let recs = try await createRecommendations(from: profile)
            recommendations = recs
            print("✅ Generated \(recs.count) recommendations")
            
        } catch {
            self.error = .analysisFailed
            throw error
        }
    }
    
    /// Clears all recommendations and profile data.
    func clearRecommendations() {
        recommendations = []
        readingProfile = nil
        error = nil
        analysisSession = nil
        recommendationSession = nil
    }
    
    // MARK: - Private Methods
    
    /// Analyzes the reading list to create a user profile.
    private func analyzeReadingList(_ books: [Book]) async throws -> ReadingProfile {
        let instructions = "You are a literary expert analyzing reading patterns. Identify specific genres, themes, and preferences."
        
        analysisSession = LanguageModelSession(instructions: instructions)
        
        let prompt = buildAnalysisPrompt(for: books)
        let response = try await analysisSession!.respond(
            to: prompt,
            generating: ProfileResponse.self
        )
        
        let profileData = response.content
        
        return ReadingProfile(
            genres: profileData.genres,
            themes: profileData.themes,
            authorStyles: profileData.authorStyles,
            preferredSubjects: profileData.subjects,
            summary: profileData.summary
        )
    }
    
    /// Creates personalized recommendations based on the reading profile.
    private func createRecommendations(from profile: ReadingProfile) async throws -> [Recommendation] {
        let instructions = "You are a book recommendation expert. Generate diverse genre suggestions with simple, searchable keywords."
        
        recommendationSession = LanguageModelSession(instructions: instructions)
        
        let prompt = buildRecommendationPrompt(for: profile)
        let response = try await recommendationSession!.respond(
            to: prompt,
            generating: RecommendationsResponse.self
        )
        
        let recsData = response.content
        
        print("✅ Parsed \(recsData.recommendations.count) recommendations")
        
        return recsData.recommendations.map { item in
            Recommendation(
                bookTitle: item.title,
                author: item.author,
                genre: item.genre,
                themes: item.themes,
                reasoning: item.reasoning,
                searchQuery: item.searchQuery,
                confidence: parseConfidence(item.confidence)
            )
        }
    }
    
    /// Builds the prompt for analyzing the reading list.
    private func buildAnalysisPrompt(for books: [Book]) -> String {
        var bookList = ""
        for (index, book) in books.enumerated() {
            bookList += "\n\(index + 1). \"\(book.title)\" by \(book.author)"
            if let description = book.description, !description.isEmpty {
                let cleanDescription = description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                bookList += "\n   \(cleanDescription.prefix(150))..."
            }
        }
        
        return """
        Analyze this reading list and identify patterns:
        \(bookList)
        
        Provide:
        - genres: Main genres as array of strings
        - themes: Recurring themes as array of strings  
        - authorStyles: Writing styles as array of strings
        - subjects: Subject areas as array of strings
        - summary: 2-3 sentences about the reader's taste
        
        Be specific and insightful about patterns across the books.
        """
    }
    
    /// Builds the prompt for generating recommendations.
    private func buildRecommendationPrompt(for profile: ReadingProfile) -> String {
        return """
        Reader enjoys:
        - Genres: \(profile.genres.joined(separator: ", "))
        - Themes: \(profile.themes.joined(separator: ", "))
        - Styles: \(profile.authorStyles.joined(separator: ", "))
        
        Generate exactly 3 diverse, specific book recommendations with actual titles and authors.
        
        For each recommendation provide:
        - title: The specific book title
        - author: The author's name
        - genre: The book's genre (e.g., "Science Fiction", "Historical Fiction")
        - themes: Array of 2-3 relevant themes from the book
        - reasoning: 1-2 sentences explaining why this book matches their taste
        - searchQuery: The book title and author as a simple search string (e.g., "Dune Frank Herbert")
        - confidence: "high", "medium", or "low"
        
        Important:
        - Recommend real, published books
        - Make recommendations diverse but aligned with preferences
        - searchQuery should be "title author" format for easy searching
        - Choose books that are well-known or critically acclaimed
        """
    }
    
    // MARK: - Helper Methods
    
    /// Parses confidence level from string.
    private func parseConfidence(_ text: String) -> Recommendation.ConfidenceLevel {
        let lowercased = text.lowercased()
        if lowercased.contains("high") {
            return .high
        } else if lowercased.contains("low") {
            return .low
        } else {
            return .medium
        }
    }
}
