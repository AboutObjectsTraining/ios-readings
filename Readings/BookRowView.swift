//
//  BookRowView.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/12/26.
//

import SwiftUI

struct BookRowView: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: book.thumbnailURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 90)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                case .failure:
                    Image(systemName: "book.closed")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                        .frame(width: 60, height: 90)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                @unknown default:
                    EmptyView()
                }
            }
            
            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text(book.formattedPrice)
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BookRowView(book: Book(
        id: 1,
        title: "Sample Book Title",
        author: "Author Name",
        thumbnailURL: nil,
        price: 9.99,
        currency: "USD",
        description: "A sample book description"
    ))
    .padding()
}
