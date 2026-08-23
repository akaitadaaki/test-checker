## 2026-08-23 test-checker 初期実装（md-reader ベース）
- 対象: Sources/TestCheckerCore/TestSpec.swift, Sources/TestChecker/ChecklistPane.swift, EditorSession.swift, Tests/TestCheckerCoreTests/TestRunTests.swift
- 問題1: `TestCase` を `Identifiable` にしたが `id` は任意(String?)のため、ID なしケースが全て同じ `nil` になり ForEach の識別子が衝突する。→ Identifiable をやめ `ForEach(id: \.line)` に変更。
- 問題2: メモ欄の `onAppear` 初期化が `onChange` を発火させ、行が表示されるたびに結果ファイルを書き込んでいた。→ `setNote` で値が変わらない場合は早期 return。
- 問題3: テストの固定エポック値を暗算で誤っていた(2025年)上に、期待値がローカルTZ依存だった。→ `DateComponents`(TZ明示)で生成し、期待値もフォーマッタ経由で組み立て。
- 問題4: `MDReaderApp.swift` のファイル名が旧名のまま。→ リネーム。
