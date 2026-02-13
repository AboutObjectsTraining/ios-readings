#  Tool Calling

## Book Detail View

1. Add a button to trigger a tool call to provide a brief book review
2. Provide a UI element to alert the user when the response is ready and allow them to view the response

## Cleanup

1. Let's move the Generate button to the top so that's it's immediately visible when the user navigates to the detail view
2. The app should scroll to the generated content when the user taps the button to view it.
3. It appears as though some of the generated content contains markdown, e.g. something to the effect of "** Some Title **". Is there a way to render that nicely?
4. Line breaks seem to be getting swallowed in the generated content, perhaps due to the configuration of the attributed string. Can you fix that?

## Refactoring

1. Okay, next up there are a couple of candidates for refactoring. Let's start with the BookDetailView -- in particular the body property. Ideally, the code in that property would be primarily about the structure of the layout rather than the gory details.
2. Next up would be the HTMLTextView. Ideally the updateUIView method would primarily contain high-level logic to make it easy to quickly grasp what it's doing.
