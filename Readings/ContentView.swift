//
//  ContentView.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/12/26.
//

import SwiftUI

struct ContentView: View {
    @State private var readingList = ReadingListManager()
    @State private var showingAddBook = false
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationStack {
            Group {
                if readingList.books.isEmpty {
                    ContentUnavailableView(
                        "Your Reading List is Empty",
                        systemImage: "books.vertical",
                        description: Text("Tap the + button to discover and add books to your reading list")
                    )
                } else {
                    List {
                        ForEach(readingList.books) { book in
                            NavigationLink(destination: BookDetailView(book: book)) {
                                BookRowView(book: book)
                            }
                        }
                        .onDelete(perform: readingList.removeBooks)
                        .onMove(perform: readingList.moveBooks)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Reading List")
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !readingList.books.isEmpty {
                        Button(editMode == .active ? "Done" : "Edit") {
                            withAnimation {
                                editMode = editMode == .active ? .inactive : .active
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddBook = true
                    } label: {
                        Label("Add Book", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBook) {
                BookSearchView()
                    .environment(readingList)
            }
        }
    }
}

#Preview {
    ContentView()
}
