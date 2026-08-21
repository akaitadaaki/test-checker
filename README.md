# MD Reader

macOS 14+ 向けの超軽量 Markdown リーダー／簡易エディタ。Electron は使わず、SwiftUI とシステム WebKit だけで動く。

## 機能

- `.md` / `.markdown` を開いて読む
- 原文の編集と保存
- 右ペインでライブプレビュー（GFM テーブル対応）
- 文字検索（⌘F、次へ ⌘G、前へ ⇧⌘G）

## 必要環境

- macOS 14 以降
- Xcode Command Line Tools（`swift`）

## 使い方

```bash
make test    # コアのテスト
make run     # 開発実行
make app     # MDReader.app を作って開く
```

アプリ起動後は ⌘O でファイルを開く。Finder から `.md` をドロップしてもよい。

## 構成

- `MarkdownCore` — 検索・HTML 変換・ファイル I/O（テスト対象）
- `MDReader` — 分割ビューの UI
