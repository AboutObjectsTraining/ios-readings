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
    
    var formattedPrice: String {
        if price == 0 {
            return "Free"
        }
        return String(format: "$%.2f", price)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "trackId"
        case title = "trackName"
        case author = "artistName"
        case thumbnailURL = "artworkUrl100"
        case price = "price"
        case currency = "currency"
        case description = "description"
    }
}

struct iTunesSearchResponse: Codable {
    let resultCount: Int
    let results: [Book]
}
