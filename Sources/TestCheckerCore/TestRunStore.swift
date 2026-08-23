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
        return resultsDirectory(for: specURL)
            .appendingPathComponent("\(f.string(from: date))-\(String(safeTester)).md")
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
