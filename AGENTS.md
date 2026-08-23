# AGENTS.md

## プロジェクト概要
Test Checker — Markdown の手動テスト仕様書を読み込み、結果を別ファイルに記録する macOS アプリ(Swift / SwiftUI)。
フォーマットは `README.md`、使い方は `docs/USAGE.md` を参照。

## 開発
- `make test` でコアのテスト、`make app` でアプリをビルドして起動。
- 機能追加・修正は TDD(Red → Green → Refactor)で進める。

## スキル
- **test-spec** (`skills/test-spec/SKILL.md`): このアプリ用のテスト仕様書を作成・更新する手順。
  「テスト仕様書を書いて」「テストケースを追加して」と依頼されたら、まずこのファイルを読んで従うこと。
  各ツール向けの参照先: Claude Code `.claude/skills/test-spec`、Codex `.codex/skills/test-spec`(いずれも symlink)、Cursor `.cursor/rules/test-spec.mdc`。
