import Foundation

/// プレビューにチェック状態とメモを重ねるための「行番号 → 状態・メモ」対応表。
public enum TestStatusOverlay {
    public struct Entry: Equatable, Codable, Sendable {
        public var status: String
        public var note: String

        public init(status: String, note: String) {
            self.status = status
            self.note = note
        }
    }

    /// 未実施は含めない(プレビュー側で装飾をリセットしてから適用するため)。
    public static func statusesByLine(spec: TestSpec, run: TestRun?) -> [Int: Entry] {
        guard let run else { return [:] }
        var result: [Int: Entry] = [:]
        for testCase in spec.cases {
            if let r = run.result(for: testCase.key) {
                result[testCase.line] = Entry(status: r.status.rawValue, note: r.note)
            }
        }
        return result
    }

    /// `{"12":{"status":"pass","note":""}}` 形式の JSON。JS の applyTestStatuses に渡す。
    public static func json(spec: TestSpec, run: TestRun?) -> String {
        let dict = Dictionary(uniqueKeysWithValues: statusesByLine(spec: spec, run: run).map { (String($0.key), $0.value) })
        guard let data = try? JSONEncoder().encode(dict) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
