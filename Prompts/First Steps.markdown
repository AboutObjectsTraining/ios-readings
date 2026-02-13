#  Initial Setup (Step 1)

## Overview

1. This is a SwiftUI app that enables a user to create and maintain one or more reading lists of ebooks.
2. The app uses the iTunes API as its data source for ebook data, metadata, and images.
3. The app initially stores data locally in plist format; later revisions could possibly switch to SwiftData.
4. The initial version of the app presents a single reading list, though support for multiple lists could be an enhancement in later versions.

## User interactions

1. The user is initially presented with an empty reading list with a navigation title "Readings", and a prompt with a title and subtitle. The title should say: "There are currently no books in the list." The subtitle should say: "Tap the + button to add a book." Please feel to improve the text of the prompts.
2. When the user taps the + button, the app should present a search UI in a card-style modal interface.
3. As the user types, a corresponding list of ebooks is presented in a scrollable list.
4. Each element of the list presents a thumbnail of the current book, along with its title, author info, and price in USD.


## Step 2

1. Let's change the initial title from "Readings" to "Reading List"
2. Let's add an Edit/Done button for the reading list that supports deletion and reordering.
3. Changing the color displayed for the price to green might make that element appear less like a button.
4. Add navigation from the reading list to a detail view showing more information and a full-size image.

### Tweaks

Let's give the image a max height of 320, and present the description in an HTML view so that the embedded HTML tags get interpreted, making sure that the text doesn't get truncated.

Let's move the image between the detail info and the description, and reduce the vertical white space to 12 points above and below the image


Let's add ratings stars to the reading list and book detail views.
