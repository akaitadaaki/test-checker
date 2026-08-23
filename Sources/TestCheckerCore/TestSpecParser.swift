import Foundation

/// GFM タスクリスト形式の仕様書を行ベースで解析する。
/// swift-markdown は `[x]` 以外の拡張記法や行番号の扱いが不便なため、自前の行走査にしている。
public enum TestSpecParser {
    private static let taskLine = try! NSRegularExpression(
        pattern: #"^[-*+]\s+\[[ xX]\]\s+(.+?)\s*$"#)
    private static let headingLine = try! NSRegularExpression(pattern: #"^(#{1,6})\s+(.+?)\s*#*\s*$"#)
    private static let detailLine = try! NSRegularExpression(pattern: #"^\s+[-*+]\s+(.+?)\s*$"#)
    private static let idPrefix = try! NSRegularExpression(pattern: #"^([A-Za-z][A-Za-z0-9_]*-\d+)\s+(.+)$"#)

    public static func parse(_ text: String) -> TestSpec {
        let lines = text.components(separatedBy: "\n")
        var spec = TestSpec()
        var headings: [String] = []   // インデックス = 見出しレベル-1
        var inCodeBlock = false
        var index = 0

        // front matter
        if lines.first == "---" {
            if let end = lines.dropFirst().firstIndex(of: "---") {
                spec.project = frontMatterValue(lines[1..<end], key: "project")
                index = end + 1
            }
        }

        while index < lines.count {
            let line = lines[index]
            let lineNumber = index + 1
            index += 1

            if line.hasPrefix("```") || line.hasPrefix("~~~") {
                inCodeBlock.toggle()
                continue
            }
            if inCodeBlock { continue }

            if let m = headingLine.firstMatch(line) {
                let level = m[1].count
                headings = Array(headings.prefix(level - 1)) + [m[2]]
                continue
            }

            guard let m = taskLine.firstMatch(line) else { continue }
            var testCase = TestCase(id: nil, title: m[1], headingPath: headings, details: [], line: lineNumber)
            if let idMatch = idPrefix.firstMatch(m[1]) {
                testCase.id = idMatch[1]
                testCase.title = idMatch[2]
            }
            // 直後のインデントされた箇条書きを詳細として取り込む
            while index < lines.count, let d = detailLine.firstMatch(lines[index]) {
                testCase.details.append(d[1])
                index += 1
            }
            spec.cases.append(testCase)
        }
        return spec
    }

    private static func frontMatterValue(_ lines: ArraySlice<String>, key: String) -> String? {
        for line in lines {
            let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2, parts[0] == key {
                return parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            }
        }
        return nil
    }
}

extension NSRegularExpression {
    /// 先頭マッチのキャプチャグループを配列で返す。`[0]` は全体。
    func firstMatch(_ s: String) -> [String]? {
        let ns = s as NSString
        guard let m = firstMatch(in: s, range: NSRange(location: 0, length: ns.length)) else { return nil }
        return (0..<m.numberOfRanges).map { i in
            let r = m.range(at: i)
            return r.location == NSNotFound ? "" : ns.substring(with: r)
        }
    }
}
