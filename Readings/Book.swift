//
//  Book.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/12/26.
//

import Foundation

struct Book: Identifiable, Codable, Equatable {
    let id: Int
    let title: String
    let author: String
    let thumbnailURL: URL?
    let price: Double
    let currency: String
    let description: String?
    let averageUserRating: Double?
    let userRatingCount: Int?
    
    var formattedPrice: String {
        if price == 0 {
            return "Free"
        }
        return String(format: "$%.2f", price)
    }
    
    var formattedRating: String {
        guard let rating = averageUserRating else {
            return "No ratings"
        }
        return String(format: "%.1f", rating)
    }
    
    var formattedRatingCount: String {
        guard let count = userRatingCount else {
            return ""
        }
        if count >= 1000 {
            return String(format: "(%.1fK)", Double(count) / 1000.0)
        }
        return "(\(count))"
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "trackId"
        case title = "trackName"
        case author = "artistName"
        case thumbnailURL = "artworkUrl100"
        case price = "price"
        case currency = "currency"
        case description = "description"
        case averageUserRating = "averageUserRating"
        case userRatingCount = "userRatingCount"
    }
}

struct iTunesSearchResponse: Codable {
    let resultCount: Int
    let results: [Book]
}
