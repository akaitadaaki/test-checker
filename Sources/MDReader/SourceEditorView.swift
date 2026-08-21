import AppKit
import SwiftUI

struct SourceEditorView: NSViewRepresentable {
    @Binding var text: String
    var matches: [NSRange]
    var currentMatchIndex: Int?

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
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
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
        textView.scrollRangeToVisible(range)
        textView.setSelectedRange(range)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        weak var textView: NSTextView?
        var lastFocus: MatchFocus?

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}

struct MatchFocus: Equatable {
    var index: Int
    var location: Int
    var length: Int
}
