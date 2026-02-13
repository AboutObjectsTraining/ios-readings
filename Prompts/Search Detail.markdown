#  Search Detail

1. Allow drilldown from the search results view to the book detail view.
2. Provide a button in the detail view to add the current book to the reading list.

## Defects and Enhancements

1. Whitespace in search field (e.g., "War and Peace") causes the search to fail every time.
2. Drilldown from the reading list results in fatal error: "No Observable object of type ReadingListManager found. A View.environmentObject(\_:) for ReadingListManager may be missing as an ancestor of this view"
3. The `price` attribute (and perhaps) others may need to be optional: "Search error: keyNotFound(CodingKeys(stringValue: "price", intValue: nil), Swift.DecodingError.Context(codingPath: [CodingKeys(stringValue: "results", intValue: nil), _CodingKey(stringValue: "Index 21", intValue: 21)], debugDescription: "No value associated with key CodingKeys(stringValue: \"price\", intValue: nil) (\"price\").", underlyingError: nil))"
4. The search field should be pre-selected so the user doesn't have to tap to begin typing.
5. The navigation title and Cancel button shouldn't disappear when the user interacts with the search field.
