import Foundation
import Testing
@testable import TestCheckerCore

struct SourcePositionTests {
    @Test func firstCharacterIsLineOne() {
        #expect(SourcePosition.line(atUTF16Offset: 0, in: "hello") == 1)
    }

    @Test func characterAfterNewlineIsLineTwo() {
        let text = "hello\nworld"
        #expect(SourcePosition.line(atUTF16Offset: 6, in: text) == 2)
    }

    @Test func newlineStillCountsAsPreviousLine() {
        #expect(SourcePosition.line(atUTF16Offset: 5, in: "hello\nworld") == 1)
    }

    @Test func offsetOfSecondLineIsAfterNewline() {
        #expect(SourcePosition.utf16Offset(ofLine: 2, in: "hello\nworld") == 6)
    }

    @Test func emptyTextIsLineOne() {
        #expect(SourcePosition.line(atUTF16Offset: 0, in: "") == 1)
        #expect(SourcePosition.utf16Offset(ofLine: 1, in: "") == 0)
    }

    @Test func japaneseLinesUseUTF16Offsets() {
        let text = "あ\nい"
        #expect(SourcePosition.line(atUTF16Offset: 2, in: text) == 2)
        #expect(SourcePosition.utf16Offset(ofLine: 2, in: text) == 2)
    }
}

struct PreviewSelectionTests {
    @Test func emphasisRendersAsVisibleText() {
        #expect(PreviewSelection.visibleText(from: "**bold**") == "bold")
    }

    @Test func headingRendersAsVisibleText() {
        #expect(PreviewSelection.visibleText(from: "# Hello") == "Hello")
    }

    @Test func plainTextStaysPlain() {
        #expect(PreviewSelection.visibleText(from: "hello") == "hello")
    }
}
