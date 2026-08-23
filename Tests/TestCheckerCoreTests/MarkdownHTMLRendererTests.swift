import Foundation
import Testing
@testable import TestCheckerCore

struct MarkdownHTMLRendererTests {
    @Test func headingBecomesH1() {
        let html = MarkdownHTMLRenderer.fragment(from: "# Hello")
        #expect(html.contains("<h1>"))
    }

    @Test func emphasisBecomesStrong() {
        let html = MarkdownHTMLRenderer.fragment(from: "**bold**")
        #expect(html.contains("<strong>bold</strong>"))
    }

    @Test func gfmTableBecomesTable() {
        let markdown = """
        | a | b |
        | --- | --- |
        | 1 | 2 |
        """
        let html = MarkdownHTMLRenderer.fragment(from: markdown)
        #expect(html.contains("<table>"))
    }

    @Test func pageWrapsFragmentWithTitle() {
        let page = MarkdownHTMLRenderer.page(from: "# Hi", title: "note.md")
        #expect(page.contains("<title>note.md</title>"))
    }

    @Test func pageEscapesTitleHTML() {
        let page = MarkdownHTMLRenderer.page(from: "hi", title: "a <b> c")
        #expect(page.contains("<title>a &lt;b&gt; c</title>"))
    }

    @Test func wrapsTopLevelBlocksWithSourceLines() {
        let html = MarkdownHTMLRenderer.fragment(
            from: """
            # Hello

            world
            """
        )
        #expect(html.contains("data-line=\"1\""))
        #expect(html.contains("data-line=\"3\""))
    }

    @Test func pageIncludesPreviewBridge() {
        let page = MarkdownHTMLRenderer.page(from: "# Hi", title: "note.md")
        #expect(page.contains("scrollToSourceLine"))
        #expect(page.contains("selectPlainText"))
    }
}
