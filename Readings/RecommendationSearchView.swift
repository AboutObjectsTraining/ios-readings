//
//  RecommendationSearchView.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/13/26.
//

import SwiftUI

/// A specialized search view for finding books based on AI recommendations.
///
/// `RecommendationSearchView` automatically searches iTunes using the AI-generated
/// query and allows users to browse and add recommended books to their reading list.
struct RecommendationSearchView: View {
    let searchQuery: String
    let recommendation: BookRecommendationService.Recommendation
    
    @Environment(\.dismiss) private var dismiss
    @Environment(ReadingListManager.self) private var readingList
    
    @State private var service = iTunesService()
    @State private var searchResults: [Book] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    
    var body: some View {
        NavigationStack {
            Group {
                if isSearching {
                    loadingView
                } else if !hasSearched {
                    placeholderView
                } else if searchResults.isEmpty {
                    noResultsView
                } else {
                    resultsListView
                }
            }
            .navigationTitle("Recommended Books")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await performSearch()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Searching for books...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var placeholderView: some View {
        ContentUnavailableView(
            "Preparing Search",
            systemImage: "magnifyingglass",
            description: Text("Getting ready to search for \(recommendation.genre) books...")
        )
    }
    
    private var noResultsView: some View {
        ContentUnavailableView(
            "No Books Found",
            systemImage: "books.vertical",
            description: Text("Try browsing the full catalog or refine your search.")
        )
    }
    
    private var resultsListView: some View {
        VStack(spacing: 0) {
            // Recommendation Context Header
            recommendationHeader
                .padding()
                .background(.regularMaterial)
            
            // Results List
            List {
                ForEach(searchResults) { book in
                    NavigationLink {
                        BookDetailView(book: book, showAddButton: true)
                    } label: {
                        BookRowView(book: book)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
    
    private var recommendationHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.blue)
                Text("AI Recommended")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
            
            Text("\(recommendation.bookTitle) by \(recommendation.author)")
                .font(.headline)
            
            Text(recommendation.reasoning)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Helper Methods
    
    private func performSearch() async {
        guard !searchQuery.isEmpty else {
            print("Error: Empty search query")
            hasSearched = true
            return
        }
        
        print("Searching for: '\(searchQuery)'")
        isSearching = true
        hasSearched = false
        
        // Small delay to ensure UI updates
        try? await Task.sleep(for: .milliseconds(100))
        
        do {
            let results = try await service.searchBooks(query: searchQuery)
            print("Search completed: \(results.count) results found")
            searchResults = results
            hasSearched = true
        } catch {
            print("Search error: \(error.localizedDescription)")
            searchResults = []
            hasSearched = true
        }
        
        isSearching = false
    }
}

#Preview {
    RecommendationSearchView(
        searchQuery: "Dune Frank Herbert",
        recommendation: BookRecommendationService.Recommendation(
            bookTitle: "Dune",
            author: "Frank Herbert",
            genre: "Science Fiction",
            themes: ["Politics", "Ecology", "Religion"],
            reasoning: "Based on your interest in epic world-building and complex political narratives, you might enjoy this classic science fiction masterpiece.",
            searchQuery: "Dune Frank Herbert",
            confidence: .high
        )
    )
    .environment(ReadingListManager())
}
