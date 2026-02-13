//
//  BookSearchView.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/12/26.
//

import SwiftUI

struct BookSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ReadingListManager.self) private var readingList
    
    @State private var service = iTunesService()
    @State private var searchText = ""
    @State private var searchResults: [Book] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            Group {
                if searchResults.isEmpty && !searchText.isEmpty && !isSearching {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "books.vertical",
                        description: Text("Try searching for a different book or author")
                    )
                } else if searchText.isEmpty {
                    ContentUnavailableView(
                        "Search for Books",
                        systemImage: "magnifyingglass",
                        description: Text("Enter a book title or author name to get started")
                    )
                } else {
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
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                prompt: "Search books..."
            )
            .focused($isSearchFieldFocused)
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onChange(of: searchText) { oldValue, newValue in
                performSearch()
            }
            .onAppear {
                // Auto-focus the search field when view appears
                isSearchFieldFocused = true
            }
            .overlay {
                if isSearching {
                    ProgressView()
                }
            }
        }
    }
    
    private func performSearch() {
        // Cancel any existing search
        searchTask?.cancel()
        
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        // Debounce search
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            
            guard !Task.isCancelled else { return }
            
            isSearching = true
            
            do {
                let results = try await service.searchBooks(query: searchText)
                if !Task.isCancelled {
                    searchResults = results
                }
            } catch {
                if !Task.isCancelled {
                    searchResults = []
                    print("Search error: \(error)")
                }
            }
            
            isSearching = false
        }
    }
}

#Preview {
    BookSearchView()
        .environment(ReadingListManager())
}
