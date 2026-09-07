import Foundation
import Testing
@testable import TestCheckerCore

struct TestStatusOverlayTests {
    let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func 行番号をキーに状態とメモを返す() {
        let spec = TestSpecParser.parse("- [ ] A-1 a\n- [ ] A-2 b")
        var run = TestRun(spec: "s.md", tester: "t", version: nil, started: now)
        run.set("A-1", status: .pass, note: "", at: now)
        run.set("A-2", status: .recheck, note: "環境差かも", at: now)
        #expect(TestStatusOverlay.statusesByLine(spec: spec, run: run) == [
            1: .init(status: "pass", note: ""),
            2: .init(status: "recheck", note: "環境差かも"),
        ])
    }

    // 位置の対応付けはブロック内の順番に依存するため、未実施の行も欠かさず含める必要がある
    // (欠けると後続ケースの表示位置が前へズレる)
    @Test func 未実施のケースもnotRunとして含める() {
        let spec = TestSpecParser.parse("- [ ] A-1 a\n- [ ] A-2 b")
        var run = TestRun(spec: "s.md", tester: "t", version: nil, started: now)
        run.set("A-2", status: .fail, note: "", at: now)
        #expect(TestStatusOverlay.statusesByLine(spec: spec, run: run) == [
            1: .init(status: "notRun", note: ""),
            2: .init(status: "fail", note: ""),
        ])
    }

    @Test func runがなくても全ケースをnotRunとして含める() {
        let spec = TestSpecParser.parse("- [ ] A-1 a")
        #expect(TestStatusOverlay.statusesByLine(spec: spec, run: nil) == [1: .init(status: "notRun", note: "")])
    }

    @Test func JSONは行番号文字列キーの辞書() throws {
        let spec = TestSpecParser.parse("- [ ] A-1 a")
        var run = TestRun(spec: "s.md", tester: "t", version: nil, started: now)
        run.set("A-1", status: .skip, note: "遅い | 後で", at: now)
        let json = TestStatusOverlay.json(spec: spec, run: run)
        let decoded = try JSONDecoder().decode([String: TestStatusOverlay.Entry].self, from: Data(json.utf8))
        #expect(decoded == ["1": .init(status: "skip", note: "遅い | 後で")])
    }
}
