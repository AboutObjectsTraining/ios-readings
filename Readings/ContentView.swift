//
//  ContentView.swift
//  Readings
//
//  Created by Jonathan Lehr on 2/12/26.
//

import SwiftUI

/// The root view of the Readings app.
///
/// `ContentView` serves as the top-level entry point for the application,
/// managing the shared `ReadingListManager` and injecting it into the
/// environment for all child views.
struct ContentView: View {
    @State private var readingList = ReadingListManager()
    
    var body: some View {
        ReadingListView()
            .environment(readingList)
    }
}

#Preview {
    ContentView()
}
