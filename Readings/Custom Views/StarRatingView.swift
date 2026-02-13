//
//  StarRatingView.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/13/26.
//

import SwiftUI

/// A view that displays a star rating visualization.
///
/// `StarRatingView` renders a 5-star rating display with filled, half-filled, and empty stars
/// based on the provided rating value. It supports different sizes and can optionally display
/// the rating count.
///
/// Example usage:
/// ```swift
/// StarRatingView(rating: 4.5, ratingCount: 127)
/// StarRatingView(rating: 3.0, size: .small)
/// ```
struct StarRatingView: View {
    let rating: Double?
    let ratingCount: Int?
    let size: Size
    
    enum Size {
        case small
        case medium
        case large
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }
        
        var font: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
    }
    
    init(rating: Double?, ratingCount: Int? = nil, size: Size = .medium) {
        self.rating = rating
        self.ratingCount = ratingCount
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: size.spacing) {
            if let rating = rating {
                // Stars
                HStack(spacing: 1) {
                    ForEach(0..<5) { index in
                        starImage(for: index, rating: rating)
                            .font(.system(size: size.iconSize))
                            .foregroundStyle(.yellow)
                    }
                }
                
                // Rating number
                Text(String(format: "%.1f", rating))
                    .font(size.font)
                    .foregroundStyle(.secondary)
                
                // Rating count
                if let count = ratingCount, count > 0 {
                    Text(formattedCount(count))
                        .font(size.font)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No ratings")
                    .font(size.font)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Returns the appropriate star image for the given position and rating.
    private func starImage(for position: Int, rating: Double) -> Image {
        let threshold = Double(position)
        let nextThreshold = Double(position + 1)
        
        if rating >= nextThreshold {
            return Image(systemName: "star.fill")
        } else if rating > threshold {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }
    
    /// Formats the rating count for display.
    private func formattedCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "(%.1fK)", Double(count) / 1000.0)
        }
        return "(\(count))"
    }
}

#Preview("With Ratings") {
    VStack(alignment: .leading, spacing: 20) {
        StarRatingView(rating: 5.0, ratingCount: 1234, size: .large)
        StarRatingView(rating: 4.5, ratingCount: 567, size: .medium)
        StarRatingView(rating: 3.7, ratingCount: 89, size: .small)
        StarRatingView(rating: 2.2, ratingCount: 12)
        StarRatingView(rating: 1.0, ratingCount: 3)
    }
    .padding()
}

#Preview("Without Ratings") {
    VStack(alignment: .leading, spacing: 20) {
        StarRatingView(rating: nil, size: .large)
        StarRatingView(rating: nil, size: .medium)
        StarRatingView(rating: nil, size: .small)
    }
    .padding()
}
