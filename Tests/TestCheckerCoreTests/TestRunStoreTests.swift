import Foundation
import Testing
@testable import TestCheckerCore

struct TestRunStoreTests {
    let now = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: TimeZone(identifier: "Asia/Tokyo"), year: 2026, month: 8, day: 23, hour: 18, minute: 30))!

    func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func 結果ディレクトリは仕様書名にresultsを付けたもの() {
        let spec = URL(fileURLWithPath: "/proj/login.md")
        #expect(TestRunStore.resultsDirectory(for: spec).path == "/proj/login.results")
    }

    @Test func 新規ファイル名は日時と担当者から作る() {
        let spec = URL(fileURLWithPath: "/proj/login.md")
        let url = TestRunStore.newRunURL(for: spec, tester: "akai", at: now, timeZone: TimeZone(identifier: "Asia/Tokyo")!)
        #expect(url.path == "/proj/login.results/20260823-1830-akai.md")
    }

    @Test func 担当者名のパス区切りやスペースは置換する() {
        let spec = URL(fileURLWithPath: "/proj/login.md")
        let url = TestRunStore.newRunURL(for: spec, tester: "a/b c", at: now, timeZone: TimeZone(identifier: "Asia/Tokyo")!)
        #expect(url.lastPathComponent == "20260823-1830-a_b_c.md")
    }

    @Test func 保存で結果ディレクトリを作り読み戻せる() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let spec = dir.appendingPathComponent("login.md")
        var run = TestRun(spec: "login.md", tester: "akai", version: nil, started: now)
        run.set("A-1", status: .pass, note: "", at: now)
        let url = TestRunStore.newRunURL(for: spec, tester: "akai", at: now, timeZone: .current)
        try TestRunStore.save(run, to: url)
        #expect(try TestRunStore.load(from: url) == run)
    }

    @Test func 既存の結果ファイルを新しい順に列挙する() throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let spec = dir.appendingPathComponent("login.md")
        let results = TestRunStore.resultsDirectory(for: spec)
        try FileManager.default.createDirectory(at: results, withIntermediateDirectories: true)
        for name in ["20260101-0900-a.md", "20260823-1830-b.md", "notes.txt"] {
            try "x".write(to: results.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }
        #expect(TestRunStore.existingRunURLs(for: spec).map(\.lastPathComponent) == ["20260823-1830-b.md", "20260101-0900-a.md"])
    }

    @Test func 結果ディレクトリがなければ空配列() {
        #expect(TestRunStore.existingRunURLs(for: URL(fileURLWithPath: "/nonexistent/x.md")).isEmpty)
    }
}
