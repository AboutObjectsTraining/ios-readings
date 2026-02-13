//
//  BookDetailView.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/12/26.
//

import SwiftUI
import FoundationModels

struct BookDetailView: View {
    let book: Book
    let showAddButton: Bool
    
    @Environment(\.dismiss) private var dismiss
    @Environment(ReadingListManager.self) private var readingList
    
    @State private var reviewService = BookReviewService()
    @State private var showReviewAlert = false
    @State private var reviewError: Error?
    @State private var scrollToReview = false
    @State private var showAddedConfirmation = false
    
    init(book: Book, showAddButton: Bool = false) {
        self.book = book
        self.showAddButton = showAddButton
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    bookInfoSection
                    bookCoverImage
                    aiReviewSection
                    descriptionSection
                }
                .padding()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showAddButton {
                    ToolbarItem(placement: .primaryAction) {
                        addToListButton
                    }
                }
            }
            .alert("Review Ready", isPresented: $showReviewAlert) {
                reviewAlertButtons
            } message: {
                reviewAlertMessage
            }
            .onChange(of: scrollToReview) { oldValue, newValue in
                handleScrollToReview(newValue, proxy: proxy)
            }
            .overlay(alignment: .bottom) {
                if showAddedConfirmation {
                    bookAddedToast
                }
            }
        }
    }
    
    // MARK: - Book Information Section
    
    private var bookInfoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(book.title)
                .font(.title)
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(book.author)
                .font(.title3)
                .foregroundStyle(.secondary)
            
            StarRatingView(
                rating: book.averageUserRating,
                ratingCount: book.userRatingCount,
                size: .medium
            )
            
            HStack {
                Text(book.formattedPrice)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                
                Spacer()
                
                if let currency = book.currency {
                    Text(currency)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Book Cover Image
    
    private var bookCoverImage: some View {
        AsyncImage(url: largeImageURL) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 8)
                    .frame(maxHeight: 320)
            case .failure:
                Image(systemName: "book.closed")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            @unknown default:
                EmptyView()
            }
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - AI Review Section
    
    @ViewBuilder
    private var aiReviewSection: some View {
        if case .available = reviewService.modelAvailability {
            VStack(alignment: .leading, spacing: 12) {
                if let review = reviewService.generatedReview {
                    generatedReviewCard(review)
                } else {
                    generateReviewButton
                }
            }
            .padding(.horizontal, 6)
        }
    }
    
    private func generatedReviewCard(_ review: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI Review")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    reviewService.clearReview()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            
            MarkdownTextView(markdownText: review)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .id("aiReview")
        }
    }
    
    private var generateReviewButton: some View {
        Button {
            Task {
                await generateReview()
            }
        } label: {
            if reviewService.isGenerating {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Generating Review...")
                }
                .frame(maxWidth: .infinity)
            } else {
                Label("Generate AI Review", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.bordered)
        .tint(.blue)
        .disabled(reviewService.isGenerating)
    }
    
    // MARK: - Description Section
    
    private var bookAddedToast: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title2)
            
            Text("Added to Reading List")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .background(.regularMaterial, in: Capsule())
        .shadow(radius: 8)
        .padding()
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showAddedConfirmation)
    }
    
    @ViewBuilder
    private var descriptionSection: some View {
        if let description = book.description, !description.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.headline)
                
                HTMLTextView(htmlString: description)
            }
            .padding(.horizontal, 6)
        }
    }
    
    // MARK: - Alert Components
    
    @ViewBuilder
    private var addToListButton: some View {
        if isBookInList {
            Button {
                // Book is already in list
            } label: {
                Label("Added", systemImage: "checkmark")
            }
            .disabled(true)
        } else {
            Button {
                addBookToList()
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
    }
    
    @ViewBuilder
    private var reviewAlertButtons: some View {
        Button("View Review") {
            scrollToReview = true
            reviewError = nil
        }
        Button("Dismiss", role: .cancel) {
            reviewError = nil
        }
    }
    
    @ViewBuilder
    private var reviewAlertMessage: some View {
        if let error = reviewError {
            Text(error.localizedDescription)
        } else {
            Text("Your AI-generated book review is ready to read!")
        }
    }
    
    // MARK: - Helper Methods
    
    private var isBookInList: Bool {
        readingList.books.contains(where: { $0.id == book.id })
    }
    
    private func addBookToList() {
        readingList.addBook(book)
        showAddedConfirmation = true
        
        // Auto-dismiss after a short delay and haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
    
    private func generateReview() async {
        do {
            try await reviewService.generateReview(for: book)
            showReviewAlert = true
        } catch {
            reviewError = error
            showReviewAlert = true
        }
    }
    
    private func handleScrollToReview(_ shouldScroll: Bool, proxy: ScrollViewProxy) {
        if shouldScroll {
            withAnimation {
                proxy.scrollTo("aiReview", anchor: .top)
            }
            scrollToReview = false
        }
    }
    
    // Convert the 100x100 thumbnail URL to a larger image
    private var largeImageURL: URL? {
        guard let thumbnailURL = book.thumbnailURL else { return nil }
        let urlString = thumbnailURL.absoluteString
        // Replace 100x100 with 600x600 for higher resolution
        let largeURLString = urlString.replacingOccurrences(of: "100x100", with: "600x600")
        return URL(string: largeURLString)
    }
}

#Preview {
        BookDetailView(book: Book(
            id: 1,
            title: "Make Your First App with Xcode",
            author: "Roelf Sluman",
            thumbnailURL: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Publication71/v4/40/62/02/4062025c-8d43-9a7a-2db2-805f48152ec6/Cover-Starters-Guide-1400x1867.png/600x600bb.jpg)"),
            price: 9.99,
            currency: "USD",
            description: "This is a longer description of the book that would give readers more context about what the book is about, its themes, and why they might want to read it. It can span multiple lines and provide detailed information.",
            averageUserRating: 4.5,
            userRatingCount: 234
        ), showAddButton: true)
        .environment(ReadingListManager())
}
