//
//  RecommendationsView.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/13/26.
//

import SwiftUI
import FoundationModels

/// A view that displays AI-generated book recommendations based on the user's reading list.
///
/// `RecommendationsView` analyzes the user's book collection and presents personalized
/// recommendations with explanations, confidence scores, and quick search capabilities.
struct RecommendationsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ReadingListManager.self) private var readingList
    
    @State private var service = BookRecommendationService()
    @State private var selectedRecommendation: BookRecommendationService.Recommendation?
    
    var body: some View {
        NavigationStack {
            Group {
                if case .available = service.modelAvailability {
                    mainContent
                } else {
                    unavailableView
                }
            }
            .navigationTitle("Discover Books")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedRecommendation) { recommendation in
                recommendationSearchView(for: recommendation)
            }
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        if service.isAnalyzing {
            analyzingView
        } else if let profile = service.readingProfile, !service.recommendations.isEmpty {
            recommendationsListView(profile: profile)
        } else if let error = service.error {
            errorView(error: error)
        } else {
            welcomeView
        }
    }
    
    // MARK: - Welcome View
    
    private var welcomeView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)
                    .padding(.top, 60)
                
                VStack(spacing: 12) {
                    Text("Discover Your Next Book")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Let AI analyze your reading list and recommend books you'll love")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "Smart Analysis",
                        description: "AI examines your books to understand your taste"
                    )
                    
                    FeatureRow(
                        icon: "book.closed",
                        title: "Personalized Picks",
                        description: "Get recommendations tailored to your interests"
                    )
                    
                    FeatureRow(
                        icon: "hand.thumbsup",
                        title: "Explained Choices",
                        description: "See why each book matches your preferences"
                    )
                    
                    FeatureRow(
                        icon: "lock.shield",
                        title: "Private & Secure",
                        description: "All analysis happens on your device"
                    )
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                Button {
                    Task {
                        await generateRecommendations()
                    }
                } label: {
                    Label("Analyze My Reading List", systemImage: "sparkles")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .disabled(readingList.books.count < 2)
                
                if readingList.books.count < 2 {
                    Text("Add at least 2 books to get recommendations")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom)
        }
    }
    
    // MARK: - Analyzing View
    
    private var analyzingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            VStack(spacing: 8) {
                Text("Analyzing Your Reading List")
                    .font(.headline)
                
                Text("This may take a moment...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Recommendations List
    
    private func recommendationsListView(profile: BookRecommendationService.ReadingProfile) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Reading Profile Summary
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.text.rectangle")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        
                        Text("Your Reading Profile")
                            .font(.headline)
                    }
                    
                    Text(profile.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(profile.genres, id: \.self) { genre in
                            TagView(text: genre, color: .blue)
                        }
                        ForEach(profile.themes.prefix(3), id: \.self) { theme in
                            TagView(text: theme, color: .purple)
                        }
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // Recommendations
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recommended for You")
                        .font(.headline)
                        .padding(.horizontal, 4)
                    
                    ForEach(service.recommendations) { recommendation in
                        RecommendationCard(recommendation: recommendation) {
                            selectedRecommendation = recommendation
                        }
                    }
                }
                
                // Generate More Button
                Button {
                    Task {
                        await generateRecommendations()
                    }
                } label: {
                    Label("Generate New Recommendations", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }
    
    // MARK: - Error View
    
    private func errorView(error: BookRecommendationService.RecommendationError) -> some View {
        ContentUnavailableView(
            "Unable to Generate Recommendations",
            systemImage: "exclamationmark.triangle",
            description: Text(error.localizedDescription)
        )
    }
    
    // MARK: - Unavailable View
    
    private var unavailableView: some View {
        ContentUnavailableView(
            "AI Not Available",
            systemImage: "brain.head.profile",
            description: Text("This feature requires Apple Intelligence, which is not available on this device.")
        )
    }
    
    // MARK: - Search View
    
    private func recommendationSearchView(for recommendation: BookRecommendationService.Recommendation) -> some View {
        RecommendationSearchView(
            searchQuery: recommendation.searchQuery,
            recommendation: recommendation
        )
        .environment(readingList)
    }
    
    // MARK: - Helper Methods
    
    private func generateRecommendations() async {
        do {
            try await service.generateRecommendations(for: readingList.books)
            
            // Validate we got recommendations
            if service.recommendations.isEmpty {
                print("Error: No recommendations were generated")
                service.error = .analysisFailed
            } else {
                print("Successfully generated \(service.recommendations.count) recommendations")
                // Debug: print search queries
                for (index, rec) in service.recommendations.enumerated() {
                    print("Recommendation \(index + 1): Genre=\(rec.genre), Search='\(rec.searchQuery)'")
                }
            }
        } catch {
            print("Recommendation error: \(error)")
            service.error = .analysisFailed
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct RecommendationCard: View {
    let recommendation: BookRecommendationService.Recommendation
    let onSearchTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.bookTitle)
                        .font(.headline)
                    
                    Text(recommendation.author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: recommendation.confidence.icon)
                        .foregroundStyle(.yellow)
                    Text(recommendation.confidence.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Themes
            FlowLayout(spacing: 6) {
                ForEach(recommendation.themes, id: \.self) { theme in
                    TagView(text: theme, color: .green)
                }
            }
            
            // Reasoning
            Text(recommendation.reasoning)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Search Button
            Button(action: onSearchTap) {
                Label("Search for Books", systemImage: "magnifyingglass")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.blue.gradient)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct TagView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, subviewSize.height)
                currentX += subviewSize.width + spacing
                size.width = max(size.width, currentX - spacing)
            }
            
            size.height = currentY + lineHeight
            self.size = size
            self.positions = positions
        }
    }
}

#Preview {
    RecommendationsView()
        .environment(ReadingListManager())
}
