//
//  ReadingListManager.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/12/26.
//

import Foundation
import SwiftUI
import Observation

@Observable
class ReadingListManager {
    var books: [Book] = []
    
    private let fileName = "ReadingList.plist"
    
    private var fileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    init() {
        loadBooks()
    }
    
    func addBook(_ book: Book) {
        // Avoid duplicates
        guard !books.contains(where: { $0.id == book.id }) else {
            return
        }
        
        books.append(book)
        saveBooks()
    }
    
    func removeBook(_ book: Book) {
        books.removeAll { $0.id == book.id }
        saveBooks()
    }
    
    func removeBooks(at offsets: IndexSet) {
        books.remove(atOffsets: offsets)
        saveBooks()
    }
    
    func moveBooks(from source: IndexSet, to destination: Int) {
        books.move(fromOffsets: source, toOffset: destination)
        saveBooks()
    }
    
    private func saveBooks() {
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let data = try encoder.encode(books)
            try data.write(to: fileURL)
        } catch {
            print("Error saving books: \(error)")
        }
    }
    
    private func loadBooks() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = PropertyListDecoder()
            books = try decoder.decode([Book].self, from: data)
        } catch {
            print("Error loading books: \(error)")
        }
    }
}
