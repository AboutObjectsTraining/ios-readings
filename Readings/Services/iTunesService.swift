//
//  iTunesService.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/12/26.
//

import Foundation

class iTunesService {
    
    func searchBooks(query: String) async throws -> [Book] {
        guard !query.isEmpty else {
            return []
        }
        
        // Trim whitespace and ensure proper encoding
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }
        
        var components = URLComponents(string: "https://itunes.apple.com/search")
        components?.queryItems = [
            URLQueryItem(name: "term", value: trimmedQuery),
            URLQueryItem(name: "media", value: "ebook"),
            URLQueryItem(name: "entity", value: "ebook"),
            URLQueryItem(name: "limit", value: "25")
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(iTunesSearchResponse.self, from: data)
        
        return response.results
    }
}
