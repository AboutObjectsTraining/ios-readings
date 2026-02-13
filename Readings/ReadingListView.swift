//
//  ReadingListView.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/13/26.
//

import SwiftUI

/// A view that displays and manages the user's reading list.
///
/// `ReadingListView` provides a full-featured reading list interface with support for:
/// - Viewing books in a scrollable list
/// - Editing mode for deletion and reordering
/// - Navigation to book details
/// - Adding new books via search
struct ReadingListView: View {
    @Environment(ReadingListManager.self) private var readingList
    
    @State private var showingAddBook = false
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationStack {
            Group {
                if readingList.books.isEmpty {
                    emptyStateView
                } else {
                    bookListView
                }
            }
            .navigationTitle("Reading List")
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !readingList.books.isEmpty {
                        editButton
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    addButton
                }
            }
            .sheet(isPresented: $showingAddBook) {
                BookSearchView()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "Your Reading List is Empty",
            systemImage: "books.vertical",
            description: Text("Tap the + button to discover and add books to your reading list")
        )
    }
    
    private var bookListView: some View {
        List {
            ForEach(readingList.books) { book in
                NavigationLink {
                    BookDetailView(book: book)
                } label: {
                    BookRowView(book: book)
                }
            }
            .onDelete(perform: readingList.removeBooks)
            .onMove(perform: readingList.moveBooks)
        }
        .listStyle(.plain)
    }
    
    private var editButton: some View {
        Button(editMode == .active ? "Done" : "Edit") {
            withAnimation {
                editMode = editMode == .active ? .inactive : .active
            }
        }
    }
    
    private var addButton: some View {
        Button {
            showingAddBook = true
        } label: {
            Label("Add Book", systemImage: "plus")
        }
    }
}

#Preview("With Books") {
    ReadingListView()
        .environment(ReadingListManager())
}

#Preview("Empty") {
    let emptyManager = ReadingListManager()
    return ReadingListView()
        .environment(emptyManager)
}
