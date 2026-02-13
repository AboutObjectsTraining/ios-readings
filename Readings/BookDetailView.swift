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
    
    @State private var reviewService = BookReviewService()
    @State private var showReviewAlert = false
    @State private var reviewError: Error?
    @State private var scrollToReview = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Book information at the top
                VStack(alignment: .leading, spacing: 6) {
                    Text(book.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(book.author)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Text(book.formattedPrice)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                        
                        Spacer()
                        
                        Text(book.currency)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Book cover image (scaled to 50%)
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
                .padding(.vertical, 12) // 12 points above and below
                
                // AI Review Button/Section below the image
                if case .available = reviewService.modelAvailability {
                    VStack(alignment: .leading, spacing: 12) {
                        if let review = reviewService.generatedReview {
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
                            
                            Text(review)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .id("aiReview") // ID for scrolling
                        } else {
                            Button {
                                Task {
                                    do {
                                        try await reviewService.generateReview(for: book)
                                        showReviewAlert = true
                                    } catch {
                                        reviewError = error
                                        showReviewAlert = true
                                    }
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
                    }
                    .padding(.horizontal, 6)
                }
                
                // Description
                if let description = book.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.headline)
                        
                        HTMLTextView(htmlString: description)
                    }
                    .padding(.horizontal, 6)
                }
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Review Ready", isPresented: $showReviewAlert) {
            Button("View Review") {
                scrollToReview = true
                reviewError = nil
            }
            Button("Dismiss", role: .cancel) {
                reviewError = nil
            }
        } message: {
            if let error = reviewError {
                Text(error.localizedDescription)
            } else {
                Text("Your AI-generated book review is ready to read!")
            }
        }
        .onChange(of: scrollToReview) { oldValue, newValue in
            if newValue {
                withAnimation {
                    proxy.scrollTo("aiReview", anchor: .top)
                }
                scrollToReview = false
            }
        }
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
            description: "This is a longer description of the book that would give readers more context about what the book is about, its themes, and why they might want to read it. It can span multiple lines and provide detailed information."
        ))
}
