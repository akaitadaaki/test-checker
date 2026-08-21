import Foundation
import Markdown

public enum MarkdownHTMLRenderer: Sendable {
    public static func fragment(from markdown: String) -> String {
        HTMLFormatter.format(markdown)
    }

    public static func page(from markdown: String, title: String) -> String {
        let body = fragment(from: markdown)
        let escapedTitle = escapeHTML(title)
        return """
        <!doctype html>
        <html lang="ja">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(escapedTitle)</title>
          <style>
            :root {
              --paper: #f2f4f7;
              --ink: #1a2430;
              --muted: #5a6a78;
              --rule: #d4dce4;
              --code: #e7eef3;
              --accent: #2f6f8f;
            }
            @media (prefers-color-scheme: dark) {
              :root {
                --paper: #12181f;
                --ink: #e7edf3;
                --muted: #93a3b3;
                --rule: #2a3540;
                --code: #1c252e;
                --accent: #7eb6ce;
              }
            }
            html, body {
              margin: 0;
              background: var(--paper);
              color: var(--ink);
            }
            body {
              font-family: "New York", "Iowan Old Style", Palatino, "Hiragino Mincho ProN", serif;
              font-size: 17px;
              line-height: 1.55;
              max-width: 40rem;
              margin: 0 auto;
              padding: 2.25rem 1.5rem 4rem;
            }
            h1, h2, h3, h4 {
              font-weight: 650;
              line-height: 1.25;
              letter-spacing: -0.015em;
            }
            h1 { font-size: 1.85rem; margin: 0 0 1.1rem; }
            h2 { font-size: 1.35rem; margin: 1.8rem 0 0.7rem; }
            h3 { font-size: 1.12rem; margin: 1.4rem 0 0.5rem; }
            p, ul, ol, blockquote, pre, table { margin: 0 0 1rem; }
            a { color: var(--accent); }
            code {
              font-family: ui-monospace, "SF Mono", Menlo, monospace;
              font-size: 0.86em;
              background: var(--code);
              padding: 0.1em 0.35em;
              border-radius: 3px;
            }
            pre {
              background: var(--code);
              border: 1px solid var(--rule);
              border-radius: 6px;
              padding: 0.9rem 1rem;
              overflow: auto;
            }
            pre code { background: none; padding: 0; }
            blockquote {
              border-left: 3px solid var(--accent);
              padding: 0.1rem 0 0.1rem 0.9rem;
              color: var(--muted);
            }
            table { border-collapse: collapse; width: 100%; }
            th, td {
              border: 1px solid var(--rule);
              padding: 0.35rem 0.55rem;
              text-align: left;
            }
            img { max-width: 100%; }
            hr { border: 0; border-top: 1px solid var(--rule); }
          </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }

    static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
