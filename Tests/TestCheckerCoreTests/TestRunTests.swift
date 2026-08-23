import Foundation
import Testing
@testable import TestCheckerCore

struct TestRunTests {
    let now = Calendar(identifier: .gregorian).date(from: DateComponents(timeZone: TimeZone(identifier: "Asia/Tokyo"), year: 2026, month: 8, day: 23, hour: 18, minute: 30))!

    @Test func 結果ファイルの往復で内容が保たれる() throws {
        var run = TestRun(spec: "login.md", tester: "akai", version: "v1.3.0", started: now)
        run.set("LOGIN-001", status: .pass, note: "", at: now)
        run.set("LOGIN-002", status: .fail, note: "500エラー #123", at: now)
        let text = run.render()
        let parsed = try TestRun.parse(text)
        #expect(parsed == run)
    }

    @Test func 描画結果はfrontMatterとGFMテーブル() {
        var run = TestRun(spec: "login.md", tester: "akai", version: nil, started: now)
        run.set("A-1", status: .recheck, note: "環境差かも", at: now)
        let text = run.render()
        #expect(text.hasPrefix("---\nspec: login.md\ntester: akai\n"))
        #expect(text.contains("| ID | 状態 | 確認日時 | メモ |"))
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd HH:mm"
        #expect(text.contains("| A-1 | RECHECK | \(f.string(from: now)) | 環境差かも |"))
    }

    @Test func メモ内のパイプはエスケープされて往復できる() throws {
        var run = TestRun(spec: "s.md", tester: "t", version: nil, started: now)
        run.set("A-1", status: .fail, note: "a | b", at: now)
        let parsed = try TestRun.parse(run.render())
        #expect(parsed.result(for: "A-1")?.note == "a | b")
    }

    @Test func 未記録のケースは未実施として扱う() {
        let run = TestRun(spec: "s.md", tester: "t", version: nil, started: now)
        #expect(run.status(for: "A-1") == .notRun)
    }

    @Test func 状態を未実施に戻すと行が消える() {
        var run = TestRun(spec: "s.md", tester: "t", version: nil, started: now)
        run.set("A-1", status: .pass, note: "", at: now)
        run.set("A-1", status: .notRun, note: "", at: now)
        #expect(run.results.isEmpty)
    }

    @Test func 集計は仕様書のケースを基準にする() {
        let spec = TestSpecParser.parse("- [ ] A-1 a\n- [ ] A-2 b\n- [ ] A-3 c\n- [ ] A-4 d\n- [ ] A-5 e")
        var run = TestRun(spec: "s.md", tester: "t", version: nil, started: now)
        run.set("A-1", status: .pass, note: "", at: now)
        run.set("A-2", status: .fail, note: "", at: now)
        run.set("A-3", status: .skip, note: "", at: now)
        run.set("A-4", status: .recheck, note: "", at: now)
        run.set("ZZ-9", status: .pass, note: "", at: now) // 仕様書にないものは数えない
        let s = TestSummary(spec: spec, run: run)
        #expect(s.total == 5)
        #expect(s.count(.pass) == 1)
        #expect(s.count(.fail) == 1)
        #expect(s.count(.skip) == 1)
        #expect(s.count(.recheck) == 1)
        #expect(s.count(.notRun) == 1)
    }

    @Test func 状態は記号と表示名を持つ() {
        #expect(TestStatus.pass.label == "PASS")
        #expect(TestStatus(label: "RECHECK") == .recheck)
        #expect(TestStatus(label: "???") == nil)
    }
}
