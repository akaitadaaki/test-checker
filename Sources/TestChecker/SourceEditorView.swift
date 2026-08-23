import AppKit
import TestCheckerCore
import SwiftUI

struct SourceEditorView: NSViewRepresentable {
    @Binding var text: String
    var matches: [NSRange]
    var currentMatchIndex: Int?
    var visibleLine: Int
    var followPreviewScroll: Bool
    var onVisibleLineChange: (Int) -> Void
    var onSelectionChange: (NSRange) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = true
        scroll.backgroundColor = NSColor(Palette.slate)
        scroll.contentView.postsBoundsChangedNotifications = true

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFindBar = false
        textView.usesFindPanel = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = NSColor(Palette.editorInk)
        textView.backgroundColor = NSColor(Palette.slate)
        textView.insertionPointColor = NSColor(Palette.copper)
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor(Palette.pool).withAlphaComponent(0.7),
            .foregroundColor: NSColor(Palette.editorInk),
        ]
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(
            width: scroll.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 14, height: 16)
        textView.string = text

        scroll.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.onVisibleLineChange = onVisibleLineChange
        context.coordinator.onSelectionChange = onSelectionChange
        context.coordinator.observeScroll(of: scroll)
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.onVisibleLineChange = onVisibleLineChange
        context.coordinator.onSelectionChange = onSelectionChange
        guard let textView = scroll.documentView as? NSTextView else { return }

        if textView.string != text {
            let selected = textView.selectedRanges
            textView.string = text
            let utf16Length = (text as NSString).length
            if let first = selected.first as? NSRange, NSMaxRange(first) <= utf16Length {
                textView.selectedRanges = selected
            }
        }

        applyHighlights(to: textView)
        focusCurrentMatch(in: textView, coordinator: context.coordinator)

        if followPreviewScroll, context.coordinator.lastAppliedLine != visibleLine {
            context.coordinator.isProgrammaticScroll = true
            context.coordinator.lastAppliedLine = visibleLine
            SourceEditorLayout.scroll(textView, toLine: visibleLine)
            DispatchQueue.main.async {
                context.coordinator.isProgrammaticScroll = false
            }
        }
    }

    static func dismantleNSView(_ scroll: NSScrollView, coordinator: Coordinator) {
        coordinator.stopObservingScroll()
    }

    private func applyHighlights(to textView: NSTextView) {
        let full = NSRange(location: 0, length: (textView.string as NSString).length)
        textView.layoutManager?.removeTemporaryAttribute(.backgroundColor, forCharacterRange: full)

        let matchColor = NSColor(Palette.pool).withAlphaComponent(0.40)
        let currentColor = NSColor(Palette.copper).withAlphaComponent(0.55)

        for (index, range) in matches.enumerated() {
            guard NSMaxRange(range) <= full.length else { continue }
            let color = index == currentMatchIndex ? currentColor : matchColor
            textView.layoutManager?.addTemporaryAttribute(
                .backgroundColor,
                value: color,
                forCharacterRange: range
            )
        }
    }

    private func focusCurrentMatch(in textView: NSTextView, coordinator: Coordinator) {
        guard let currentMatchIndex, matches.indices.contains(currentMatchIndex) else { return }
        let range = matches[currentMatchIndex]
        let focus = MatchFocus(index: currentMatchIndex, location: range.location, length: range.length)
        guard coordinator.lastFocus != focus else { return }
        coordinator.lastFocus = focus
        coordinator.isProgrammaticScroll = true
        textView.scrollRangeToVisible(range)
        textView.setSelectedRange(range)
        DispatchQueue.main.async {
            coordinator.isProgrammaticScroll = false
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        weak var textView: NSTextView?
        var lastFocus: MatchFocus?
        var lastAppliedLine = 0
        var isProgrammaticScroll = false
        var onVisibleLineChange: ((Int) -> Void)?
        var onSelectionChange: ((NSRange) -> Void)?
        private var boundsObserver: NSObjectProtocol?

        init(text: Binding<String>) {
            self.text = text
        }

        deinit {
            if let boundsObserver {
                NotificationCenter.default.removeObserver(boundsObserver)
            }
        }

        func observeScroll(of scroll: NSScrollView) {
            stopObservingScroll()
            boundsObserver = NotificationCenter.default.addObserver(
                forName: NSView.boundsDidChangeNotification,
                object: scroll.contentView,
                queue: .main
            ) { [weak self] _ in
                self?.boundsDidChange()
            }
        }

        func stopObservingScroll() {
            if let boundsObserver {
                NotificationCenter.default.removeObserver(boundsObserver)
                self.boundsObserver = nil
            }
        }

        func boundsDidChange() {
            guard !isProgrammaticScroll, let textView else { return }
            let line = SourceEditorLayout.firstVisibleLine(in: textView)
            lastAppliedLine = line
            onVisibleLineChange?(line)
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            onSelectionChange?(textView.selectedRange())
        }
    }
}

enum SourceEditorLayout {
    static func scroll(_ textView: NSTextView, toLine line: Int) {
        guard let layout = textView.layoutManager, let container = textView.textContainer else { return }
        let offset = SourcePosition.utf16Offset(ofLine: line, in: textView.string)
        let ns = textView.string as NSString
        let location = min(offset, ns.length)
        let range = ns.lineRange(for: NSRange(location: location, length: 0))
        let glyphRange = layout.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var rect = layout.boundingRect(forGlyphRange: glyphRange, in: container)
        rect.origin.y += textView.textContainerInset.height
        textView.scroll(NSPoint(x: 0, y: rect.minY))
    }

    static func firstVisibleLine(in textView: NSTextView) -> Int {
        guard let layout = textView.layoutManager, let container = textView.textContainer else {
            return 1
        }
        let visible = textView.visibleRect
        let inset = textView.textContainerInset
        let point = NSPoint(x: visible.minX + inset.width, y: visible.minY + inset.height)
        let glyphIndex = layout.glyphIndex(for: point, in: container)
        let charIndex = layout.characterIndexForGlyph(at: glyphIndex)
        return SourcePosition.line(atUTF16Offset: charIndex, in: textView.string)
    }
}

struct MatchFocus: Equatable {
    var index: Int
    var location: Int
    var length: Int
}
