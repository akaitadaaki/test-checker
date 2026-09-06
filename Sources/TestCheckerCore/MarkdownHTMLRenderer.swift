import Foundation
import Markdown

public enum MarkdownHTMLRenderer: Sendable {
    public static func fragment(from markdown: String) -> String {
        let document = Document(parsing: markdown)
        return document.children.map { child in
            let inner = HTMLFormatter.format(child)
            guard let range = child.range else { return inner }
            let start = range.lowerBound.line
            let end = max(start, range.upperBound.line)
            return "<div class=\"md-block\" data-line=\"\(start)\" data-end-line=\"\(end)\">\(inner)</div>"
        }.joined(separator: "\n")
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
              margin: 0;
              padding: 2.25rem 2rem 4rem;
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
            .md-block { scroll-margin-top: 0.5rem; }
            :root {
              --pass: #2e9e5b;
              --fail: #cc4440;
              --skip: #8a97a3;
              --recheck: #d98324;
            }
            @media (prefers-color-scheme: dark) {
              :root {
                --pass: #4cc07a;
                --fail: #e0625e;
                --skip: #9aa8b4;
                --recheck: #e69a45;
              }
            }
            li.test-item {
              list-style: none;
              border-left: 3px solid transparent;
              border-radius: 4px;
              padding: 0.12em 0.5em 0.12em 0.6em;
              margin: 0.12em 0 0.12em -1.1em;
            }
            li.test-item > input[type="checkbox"] { display: none; }
            .test-mark {
              display: inline-block;
              width: 1.15em;
              font-family: ui-monospace, "SF Mono", Menlo, monospace;
              font-weight: 700;
              margin-right: 0.35em;
            }
            li.test-pass    { border-left-color: var(--pass);    background: color-mix(in srgb, var(--pass) 12%, transparent); }
            li.test-fail    { border-left-color: var(--fail);    background: color-mix(in srgb, var(--fail) 12%, transparent); }
            li.test-skip    { border-left-color: var(--skip);    background: color-mix(in srgb, var(--skip) 14%, transparent); color: var(--muted); }
            li.test-recheck { border-left-color: var(--recheck); background: color-mix(in srgb, var(--recheck) 14%, transparent); }
            .test-note {
              display: block;
              font-size: 0.82em;
              line-height: 1.4;
              margin-top: 0.25em;
              padding: 0.2em 0.55em;
              border-radius: 4px;
              border: 1px dashed;
              width: fit-content;
              color: var(--muted);
            }
            .test-note::before {
              content: "💬 メモ: ";
              font-weight: 650;
            }
            li.test-pass    > .test-note { border-color: var(--pass); }
            li.test-fail    > .test-note { border-color: var(--fail); color: var(--fail); }
            li.test-skip    > .test-note { border-color: var(--skip); }
            li.test-recheck > .test-note { border-color: var(--recheck); color: var(--recheck); }
            li.test-pass    > .test-mark { color: var(--pass); }
            li.test-fail    > .test-mark { color: var(--fail); }
            li.test-skip    > .test-mark { color: var(--skip); }
            li.test-recheck > .test-mark { color: var(--recheck); }
            ::selection {
              background: rgba(199, 90, 46, 0.35);
              color: inherit;
            }
          </style>
        </head>
        <body>
        \(body)
        <script>
        \(Self.previewBridgeScript)
        </script>
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

    static let previewBridgeScript = #"""
    const PreviewBridge = {
      ignoreScroll: false,
      ignoreTimer: null,
      blocks() {
        return Array.from(document.querySelectorAll('.md-block[data-line]'));
      },
      scrollToSourceLine(line) {
        this.ignoreScroll = true;
        const blocks = this.blocks();
        if (blocks.length === 0) {
          this.clearIgnoreLater();
          return;
        }
        let prev = blocks[0];
        let next = blocks[blocks.length - 1];
        for (const el of blocks) {
          const start = Number(el.dataset.line);
          if (start <= line) prev = el;
          if (start >= line) { next = el; break; }
        }
        const prevLine = Number(prev.dataset.line);
        const nextLine = Number(next.dataset.line);
        let y = prev.offsetTop;
        if (next !== prev && nextLine > prevLine) {
          const t = (line - prevLine) / (nextLine - prevLine);
          y = prev.offsetTop + t * (next.offsetTop - prev.offsetTop);
        }
        window.scrollTo(0, Math.max(0, y - 8));
        this.clearIgnoreLater();
      },
      lineAtScroll() {
        const blocks = this.blocks();
        if (blocks.length === 0) return 1;
        const y = window.scrollY + 8;
        let prev = blocks[0];
        let next = blocks[blocks.length - 1];
        for (const el of blocks) {
          if (el.offsetTop <= y) prev = el;
          if (el.offsetTop >= y) { next = el; break; }
        }
        const prevLine = Number(prev.dataset.line);
        const nextLine = Number(next.dataset.line);
        if (next === prev || nextLine <= prevLine) return prevLine;
        const span = next.offsetTop - prev.offsetTop;
        if (span <= 0) return prevLine;
        const t = (y - prev.offsetTop) / span;
        return Math.max(1, Math.round(prevLine + t * (nextLine - prevLine)));
      },
      clearIgnoreLater() {
        clearTimeout(this.ignoreTimer);
        this.ignoreTimer = setTimeout(() => { this.ignoreScroll = false; }, 140);
      },
      selectPlainText(raw, visible, line) {
        const sel = window.getSelection();
        sel.removeAllRanges();
        const needles = [];
        if (visible) needles.push(visible);
        if (raw && raw !== visible) needles.push(raw);
        const preferred = line
          ? document.querySelector('.md-block[data-line="' + String(line) + '"]')
          : null;
        for (const needle of needles) {
          if (preferred && this.selectNeedle(needle, preferred)) return true;
          if (this.selectNeedle(needle, document.body)) return true;
        }
        return false;
      },
      selectNeedle(needle, root) {
        if (!needle || !root) return false;
        const nodes = [];
        const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
        let full = '';
        let node;
        while ((node = walker.nextNode())) {
          nodes.push({ node, start: full.length });
          full += node.data;
        }
        let idx = full.indexOf(needle);
        const length = needle.length;
        if (idx < 0) {
          idx = full.toLowerCase().indexOf(needle.toLowerCase());
          if (idx < 0) return false;
        }
        const start = this.pointAt(nodes, idx);
        const end = this.pointAt(nodes, idx + length);
        if (!start || !end) return false;
        const range = document.createRange();
        range.setStart(start.node, start.offset);
        range.setEnd(end.node, end.offset);
        const sel = window.getSelection();
        sel.removeAllRanges();
        sel.addRange(range);
        const parent = start.node.parentElement;
        if (parent) parent.scrollIntoView({ block: 'nearest', inline: 'nearest' });
        return true;
      },
      pointAt(nodes, index) {
        for (let i = 0; i < nodes.length; i++) {
          const item = nodes[i];
          const nextStart = item.start + item.node.data.length;
          if (index <= nextStart) {
            return { node: item.node, offset: Math.max(0, index - item.start) };
          }
        }
        const last = nodes[nodes.length - 1];
        if (!last) return null;
        return { node: last.node, offset: last.node.data.length };
      },
      // 状態: {"12":{"status":"pass","note":"..."}} 形式。列0のタスク項目(li直下にcheckbox)へ行順に対応付ける。
      // パーサ(TestSpecParser)と同じく、ネストしたタスクは対象外。
      applyTestStatuses(byLine) {
        const marks = { pass: '\u2713', fail: '\u2715', skip: '\u2212', recheck: '?' };
        const lines = Object.keys(byLine).map(Number).sort((a, b) => a - b);
        for (const block of this.blocks()) {
          const start = Number(block.dataset.line);
          const end = Number(block.dataset.endLine || block.dataset.line);
          const items = Array.from(block.querySelectorAll(':scope > ul > li, :scope > ol > li'))
            .filter(li => li.querySelector(':scope > input[type="checkbox"]'));
          const blockLines = lines.filter(l => l >= start && l <= end);
          items.forEach((li, i) => {
            li.classList.remove('test-item', 'test-pass', 'test-fail', 'test-skip', 'test-recheck');
            const mark = li.querySelector(':scope > .test-mark');
            if (mark) mark.remove();
            const oldNote = li.querySelector(':scope > .test-note');
            if (oldNote) oldNote.remove();
            const entry = i < blockLines.length ? byLine[blockLines[i]] : null;
            if (!entry) return;
            li.classList.add('test-item', 'test-' + entry.status);
            const span = document.createElement('span');
            span.className = 'test-mark';
            span.textContent = marks[entry.status] || '';
            li.insertBefore(span, li.firstChild);
            if (entry.note) {
              const note = document.createElement('span');
              note.className = 'test-note';
              note.textContent = entry.note;
              li.appendChild(note);
            }
          });
        }
      }
    };
    window.applyTestStatuses = (byLine) => PreviewBridge.applyTestStatuses(byLine);
    window.scrollToSourceLine = (line) => PreviewBridge.scrollToSourceLine(line);
    window.selectPlainText = (raw, visible, line) => PreviewBridge.selectPlainText(raw, visible, line);
    let scrollTick = null;
    window.addEventListener('scroll', () => {
      if (PreviewBridge.ignoreScroll) return;
      clearTimeout(scrollTick);
      scrollTick = setTimeout(() => {
        try {
          webkit.messageHandlers.previewScroll.postMessage(PreviewBridge.lineAtScroll());
        } catch (e) {}
      }, 20);
    }, { passive: true });
    """#
}
