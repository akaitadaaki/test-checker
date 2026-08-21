import Foundation
import Testing
@testable import MarkdownCore

struct RecentFilesStoreTests {
    @Test func recordsNewestFirst() {
        var store = RecentFilesStore(limit: 10)
        store.record(URL(fileURLWithPath: "/tmp/a.md"), fileExists: { _ in true })
        store.record(URL(fileURLWithPath: "/tmp/b.md"), fileExists: { _ in true })

        #expect(store.paths == ["/tmp/b.md", "/tmp/a.md"])
    }

    @Test func reRecordingMovesFileToFront() {
        var store = RecentFilesStore(limit: 10)
        store.record(URL(fileURLWithPath: "/tmp/a.md"), fileExists: { _ in true })
        store.record(URL(fileURLWithPath: "/tmp/b.md"), fileExists: { _ in true })
        store.record(URL(fileURLWithPath: "/tmp/a.md"), fileExists: { _ in true })

        #expect(store.paths == ["/tmp/a.md", "/tmp/b.md"])
    }

    @Test func dropsOldestWhenOverLimit() {
        var store = RecentFilesStore(limit: 2)
        store.record(URL(fileURLWithPath: "/tmp/a.md"), fileExists: { _ in true })
        store.record(URL(fileURLWithPath: "/tmp/b.md"), fileExists: { _ in true })
        store.record(URL(fileURLWithPath: "/tmp/c.md"), fileExists: { _ in true })

        #expect(store.paths == ["/tmp/c.md", "/tmp/b.md"])
    }

    @Test func prunesMissingFilesBeforeRecording() {
        var store = RecentFilesStore(limit: 2)
        store.record(URL(fileURLWithPath: "/tmp/gone.md"), fileExists: { _ in true })
        store.record(URL(fileURLWithPath: "/tmp/here.md"), fileExists: { $0.hasSuffix("here.md") })

        #expect(store.paths == ["/tmp/here.md"])
    }

    @Test func filesSkipsPathsThatDoNotExist() {
        var store = RecentFilesStore(limit: 10)
        store.record(URL(fileURLWithPath: "/tmp/gone.md"), fileExists: { _ in true })
        store.record(URL(fileURLWithPath: "/tmp/here.md"), fileExists: { _ in true })

        let files = store.files(fileExists: { $0.hasSuffix("here.md") })
        #expect(files.map(\.url.path) == ["/tmp/here.md"])
    }

    @Test func menuTitleIncludesParentFolder() {
        let file = RecentFile(url: URL(fileURLWithPath: "/Users/akai/notes/readme.md"))
        #expect(file.menuTitle == "readme.md — notes")
    }

    @Test func jsonRoundTripPreservesOrder() throws {
        var store = RecentFilesStore(limit: 10)
        store.record(URL(fileURLWithPath: "/tmp/a.md"), fileExists: { _ in true })
        store.record(URL(fileURLWithPath: "/tmp/b.md"), fileExists: { _ in true })

        let loaded = try RecentFilesStore.load(from: store.json(), limit: 10)
        #expect(loaded.paths == ["/tmp/b.md", "/tmp/a.md"])
    }

    @Test func clearRemovesAllPaths() {
        var store = RecentFilesStore(limit: 10)
        store.record(URL(fileURLWithPath: "/tmp/a.md"), fileExists: { _ in true })
        store.clear()
        #expect(store.paths.isEmpty)
    }
}
