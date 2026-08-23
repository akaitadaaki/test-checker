import Foundation
import Testing
@testable import TestCheckerCore

struct TextSearcherTests {
    @Test func emptyQueryReturnsNoMatches() {
        #expect(TextSearcher.findMatches(in: "hello", query: "").isEmpty)
    }

    @Test func whitespaceOnlyQueryReturnsNoMatches() {
        #expect(TextSearcher.findMatches(in: "hello", query: "   ").isEmpty)
    }

    @Test func findsCaseInsensitiveMatches() {
        let ranges = TextSearcher.findMatches(in: "Hello hello HELLO", query: "hello")
        #expect(ranges.count == 3)
    }

    @Test func caseSensitiveDoesNotMatchDifferentCase() {
        let ranges = TextSearcher.findMatches(
            in: "Hello hello",
            query: "Hello",
            caseSensitive: true
        )
        #expect(ranges.count == 1)
    }

    @Test func findsJapaneseSubstringAtExpectedRange() {
        let text = "これは検索テストです"
        let ranges = TextSearcher.findMatches(in: text, query: "検索")
        #expect((text as NSString).substring(with: ranges[0]) == "検索")
    }

    @Test func returnsEmptyWhenQueryIsAbsent() {
        #expect(TextSearcher.findMatches(in: "abc", query: "z").isEmpty)
    }

    @Test func treatsRegexMetacharactersAsLiteral() {
        let ranges = TextSearcher.findMatches(in: "price is $5.00", query: "$5.00")
        #expect(ranges.count == 1)
    }
}

struct SearchNavigatorTests {
    @Test func nextFromNilSelectsFirst() {
        #expect(SearchNavigator.advance(from: nil, matchCount: 3, direction: .forward) == 0)
    }

    @Test func nextWrapsFromLastToFirst() {
        #expect(SearchNavigator.advance(from: 2, matchCount: 3, direction: .forward) == 0)
    }

    @Test func previousWrapsFromFirstToLast() {
        #expect(SearchNavigator.advance(from: 0, matchCount: 3, direction: .backward) == 2)
    }

    @Test func previousFromNilSelectsLast() {
        #expect(SearchNavigator.advance(from: nil, matchCount: 3, direction: .backward) == 2)
    }

    @Test func zeroMatchesReturnsNil() {
        #expect(SearchNavigator.advance(from: 0, matchCount: 0, direction: .forward) == nil)
    }
}
