import Foundation

/// 仕様書(md)から抽出した1つのテストケース。
public struct TestCase: Equatable, Sendable {
    /// 任意の明示ID(例: LOGIN-001)。タイトル先頭の `英数字-数字` 形式を採用する。
    public var id: String?
    public var title: String
    /// 所属する見出しの階層(例: ["ログイン", "正常系"])。
    public var headingPath: [String]
    /// 子リストに書かれた手順・期待などの補足行。
    public var details: [String]
    /// 仕様書内の1始まり行番号。
    public var line: Int

    /// 結果ファイルとの突き合わせに使うキー。IDがあればID、なければ見出しパス+タイトル。
    public var key: String {
        id ?? (headingPath + [title]).joined(separator: "/")
    }
}

/// 仕様書全体。
public struct TestSpec: Equatable, Sendable {
    public var project: String?
    public var cases: [TestCase]

    public init(project: String? = nil, cases: [TestCase] = []) {
        self.project = project
        self.cases = cases
    }
}
