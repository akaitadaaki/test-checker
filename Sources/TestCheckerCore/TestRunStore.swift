import Foundation

/// 結果ファイルの置き場所とファイル入出力。
/// 仕様書 `login.md` に対し `login.results/20260823-1830-akai.md` のように保存する。
public enum TestRunStore {
    public static func resultsDirectory(for specURL: URL) -> URL {
        let base = specURL.deletingPathExtension().lastPathComponent
        return specURL.deletingLastPathComponent().appendingPathComponent("\(base).results", isDirectory: true)
    }

    public static func newRunURL(for specURL: URL, tester: String, at date: Date, timeZone: TimeZone) -> URL {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = timeZone
        f.dateFormat = "yyyyMMdd-HHmm"
        let safeTester = tester.map { ch -> Character in
            ch == "/" || ch == ":" || ch == "\\" || ch.isWhitespace ? "_" : ch
        }
        let dir = resultsDirectory(for: specURL)
        let base = "\(f.string(from: date))-\(String(safeTester))"
        // 同じ分に同じ担当者が開始した場合は既存ファイルを上書きせず連番を付ける
        var candidate = dir.appendingPathComponent("\(base).md")
        var n = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = dir.appendingPathComponent("\(base)-\(n).md")
            n += 1
        }
        return candidate
    }

    /// 新しい(ファイル名の降順)順に返す。`.md` 以外は無視する。
    public static func existingRunURLs(for specURL: URL) -> [URL] {
        let dir = resultsDirectory(for: specURL)
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return [] }
        return names.filter { $0.hasSuffix(".md") }.sorted(by: >).map { dir.appendingPathComponent($0) }
    }

    public static func save(_ run: TestRun, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try run.render().write(to: url, atomically: true, encoding: .utf8)
    }

    public static func load(from url: URL) throws -> TestRun {
        try TestRun.parse(String(contentsOf: url, encoding: .utf8))
    }
}
