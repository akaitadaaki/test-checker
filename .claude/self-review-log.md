## 2026-08-23 test-checker 初期実装（md-reader ベース）
- 対象: Sources/TestCheckerCore/TestSpec.swift, Sources/TestChecker/ChecklistPane.swift, EditorSession.swift, Tests/TestCheckerCoreTests/TestRunTests.swift
- 問題1: `TestCase` を `Identifiable` にしたが `id` は任意(String?)のため、ID なしケースが全て同じ `nil` になり ForEach の識別子が衝突する。→ Identifiable をやめ `ForEach(id: \.line)` に変更。
- 問題2: メモ欄の `onAppear` 初期化が `onChange` を発火させ、行が表示されるたびに結果ファイルを書き込んでいた。→ `setNote` で値が変わらない場合は早期 return。
- 問題3: テストの固定エポック値を暗算で誤っていた(2025年)上に、期待値がローカルTZ依存だった。→ `DateComponents`(TZ明示)で生成し、期待値もフォーマッタ経由で組み立て。
- 問題4: `MDReaderApp.swift` のファイル名が旧名のまま。→ リネーム。
- 問題5（実機で判明）: `run?.set(..., note: note(for:))` のように、`run` への mutating 呼び出しの引数内で `run` を読んでいたため Swift の排他アクセス違反で SIGABRT。→ 引数を先にローカル変数へ取り出してから呼び出す。`setNote` の `checkedAt` も同様に修正。
## 2026-09-07 プレビューのチェック位置ズレ修正(ユーザー報告で判明)
- 対象: Sources/TestCheckerCore/TestStatusOverlay.swift, MarkdownHTMLRenderer.swift(JS)
- 問題: プレビューへ渡す行→状態の対応表から未実施ケースを除外していた。JS はブロック内の checkbox 項目全件を行リストと順番で突き合わせるため、途中の項目だけチェックすると状態がブロック先頭の項目に表示された(MS10-208 → MS10-205)。
- 検証の失敗: 前日のシミュレーション検証は「全ケースに状態がある」前提のデータで行ったため、この欠落パターンを検出できなかった。順序依存の突き合わせを検証するときは、部分的なデータ(歯抜け)のケースを必ず含めること。
- 修正方針: 対応表に全ケースを含め、未実施は notRun として送り JS 側で装飾をスキップ。テストを契約変更(Red)→実装(Green)で更新。
