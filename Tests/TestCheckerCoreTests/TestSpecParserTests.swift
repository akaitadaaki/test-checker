import Testing
@testable import TestCheckerCore

struct TestSpecParserTests {
    @Test func 単一のタスク行を1ケースとして抽出する() {
        let spec = TestSpecParser.parse("- [ ] LOGIN-001 正しいID/PWでログインできる\n")
        #expect(spec.cases.count == 1)
        #expect(spec.cases[0].id == "LOGIN-001")
        #expect(spec.cases[0].title == "正しいID/PWでログインできる")
        #expect(spec.cases[0].line == 1)
    }

    @Test func IDがない場合は見出しパスとタイトルからキーを作る() {
        let spec = TestSpecParser.parse("""
        # ログイン
        ## 正常系
        - [ ] ログインできる
        """)
        #expect(spec.cases[0].id == nil)
        #expect(spec.cases[0].headingPath == ["ログイン", "正常系"])
        #expect(spec.cases[0].key == "ログイン/正常系/ログインできる")
    }

    @Test func IDがある場合はキーはIDそのもの() {
        let spec = TestSpecParser.parse("# A\n- [ ] X-1 title")
        #expect(spec.cases[0].key == "X-1")
    }

    @Test func タスクでない箇条書きと子リストは無視する() {
        let spec = TestSpecParser.parse("""
        - [ ] A-1 親
          - 手順: 入力する
          - 期待: 遷移する
        - ただのメモ
        """)
        #expect(spec.cases.count == 1)
        #expect(spec.cases[0].details == ["手順: 入力する", "期待: 遷移する"])
    }

    @Test func チェック済みやアスタリスク記法も受け付ける() {
        let spec = TestSpecParser.parse("* [x] A-1 done\n- [X] A-2 done2")
        #expect(spec.cases.map(\.id) == ["A-1", "A-2"])
    }

    @Test func frontMatterからプロジェクト名を読む() {
        let spec = TestSpecParser.parse("""
        ---
        project: ログイン機能
        ---
        - [ ] A-1 t
        """)
        #expect(spec.project == "ログイン機能")
        #expect(spec.cases[0].line == 4)
    }

    @Test func コードブロック内のタスク行は無視する() {
        let spec = TestSpecParser.parse("```\n- [ ] A-1 not a test\n```\n- [ ] A-2 real")
        #expect(spec.cases.map(\.id) == ["A-2"])
    }
}
