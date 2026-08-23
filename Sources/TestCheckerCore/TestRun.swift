import Foundation

/// テストケース1件の状態。
public enum TestStatus: String, CaseIterable, Sendable, Codable {
    case notRun, pass, fail, skip, recheck

    /// 結果ファイルに書く表記。
    public var label: String {
        switch self {
        case .notRun: "-"
        case .pass: "PASS"
        case .fail: "FAIL"
        case .skip: "SKIP"
        case .recheck: "RECHECK"
        }
    }

    public init?(label: String) {
        guard let s = Self.allCases.first(where: { $0.label == label }) else { return nil }
        self = s
    }
}

/// 1ケースの判定結果。
public struct TestResult: Equatable, Sendable {
    public var status: TestStatus
    public var checkedAt: Date
    public var note: String
}

public enum TestRunError: Error, Equatable {
    case missingFrontMatter
    case invalidRow(line: Int)
}

/// 1回の実施(= 結果ファイル1つ)。仕様書には触らず、ここにだけ結果を書く。
public struct TestRun: Equatable, Sendable {
    public var spec: String
    public var tester: String
    public var version: String?
    public var started: Date
    /// キー → 結果。未記録は未実施扱い。
    public private(set) var results: [String: TestResult] = [:]

    public init(spec: String, tester: String, version: String?, started: Date) {
        self.spec = spec
        self.tester = tester
        self.version = version
        self.started = started
    }

    public func status(for key: String) -> TestStatus { results[key]?.status ?? .notRun }
    public func result(for key: String) -> TestResult? { results[key] }

    public mutating func set(_ key: String, status: TestStatus, note: String, at date: Date) {
        if status == .notRun {
            results[key] = nil
        } else {
            results[key] = TestResult(status: status, checkedAt: date, note: note)
        }
    }

    // MARK: - 入出力

    private static var minuteFormat: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }

    private static var isoFormat: ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }

    public func render() -> String {
        var out = "---\nspec: \(spec)\ntester: \(tester)\n"
        if let version { out += "version: \(version)\n" }
        out += "started: \(Self.isoFormat.string(from: started))\n---\n\n"
        out += "| ID | 状態 | 確認日時 | メモ |\n|---|---|---|---|\n"
        for key in results.keys.sorted() {
            let r = results[key]!
            out += "| \(Self.escape(key)) | \(r.status.label) | \(Self.minuteFormat.string(from: r.checkedAt)) | \(Self.escape(r.note)) |\n"
        }
        return out
    }

    public static func parse(_ text: String) throws -> TestRun {
        let lines = text.components(separatedBy: "\n")
        guard lines.first == "---", let end = lines.dropFirst().firstIndex(of: "---") else {
            throw TestRunError.missingFrontMatter
        }
        var meta: [String: String] = [:]
        for line in lines[1..<end] {
            let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 { meta[parts[0]] = parts[1] }
        }
        guard let spec = meta["spec"], let tester = meta["tester"],
              let startedText = meta["started"], let started = isoFormat.date(from: startedText)
        else { throw TestRunError.missingFrontMatter }

        var run = TestRun(spec: spec, tester: tester, version: meta["version"], started: started)
        for (offset, line) in lines[(end + 1)...].enumerated() where line.hasPrefix("|") {
            let cells = splitRow(line)
            guard cells.count == 4 else { throw TestRunError.invalidRow(line: end + 2 + offset) }
            if cells[0] == "ID" || cells[0].allSatisfy({ $0 == "-" || $0 == ":" }) { continue }
            guard let status = TestStatus(label: cells[1]), let date = minuteFormat.date(from: cells[2])
            else { throw TestRunError.invalidRow(line: end + 2 + offset) }
            run.set(cells[0], status: status, note: cells[3], at: date)
        }
        return run
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "|", with: "\\|").replacingOccurrences(of: "\n", with: " ")
    }

    /// `\|` をセル内の文字として扱いつつ行をセルに分割する。
    private static func splitRow(_ line: String) -> [String] {
        var cells: [String] = []
        var current = ""
        var escaped = false
        for ch in line {
            if escaped { current.append(ch); escaped = false; continue }
            if ch == "\\" { escaped = true; continue }
            if ch == "|" { cells.append(current); current = ""; continue }
            current.append(ch)
        }
        cells.append(current)
        // 先頭と末尾の空セルを落とす
        return cells.dropFirst().dropLast().map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

/// 仕様書と結果の突き合わせ集計。
public struct TestSummary: Equatable, Sendable {
    public let total: Int
    private let counts: [TestStatus: Int]

    public init(spec: TestSpec, run: TestRun) {
        var counts: [TestStatus: Int] = [:]
        for c in spec.cases { counts[run.status(for: c.key), default: 0] += 1 }
        self.counts = counts
        self.total = spec.cases.count
    }

    public func count(_ status: TestStatus) -> Int { counts[status] ?? 0 }
}
