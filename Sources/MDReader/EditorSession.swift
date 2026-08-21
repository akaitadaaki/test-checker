import AppKit
import Foundation
import MarkdownCore
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class EditorSession {
    var document = MarkdownDocument()
    var findQuery = ""
    var isFindPresented = false
    var isCaseSensitive = false
    var matches: [NSRange] = []
    var currentMatchIndex: Int?
    var previewMarkdown = ""
    var errorMessage: String?
    var findFocusToken = 0

    var windowTitle: String {
        document.isDirty ? "\(document.displayName) — Edited" : document.displayName
    }

    var matchLabel: String {
        let query = findQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return "" }
        if matches.isEmpty { return "0" }
        if let currentMatchIndex {
            return "\(currentMatchIndex + 1)/\(matches.count)"
        }
        return "\(matches.count)"
    }

    var previewBaseURL: URL? {
        document.fileURL?.deletingLastPathComponent()
    }

    var previewHTML: String {
        MarkdownHTMLRenderer.page(from: previewMarkdown, title: document.displayName)
    }

    var hasFindQuery: Bool {
        !findQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var previewTask: Task<Void, Never>?

    init() {
        previewMarkdown = document.text
    }

    func documentTextDidChange() {
        refreshMatches(resetSelection: false)
        schedulePreview()
    }

    func findQueryDidChange() {
        refreshMatches(resetSelection: true)
    }

    func refreshMatches(resetSelection: Bool) {
        matches = TextSearcher.findMatches(
            in: document.text,
            query: findQuery,
            caseSensitive: isCaseSensitive
        )
        if matches.isEmpty {
            currentMatchIndex = nil
        } else if resetSelection || currentMatchIndex == nil {
            currentMatchIndex = 0
        } else if let currentMatchIndex, currentMatchIndex >= matches.count {
            self.currentMatchIndex = 0
        }
    }

    func findNext() {
        currentMatchIndex = SearchNavigator.advance(
            from: currentMatchIndex,
            matchCount: matches.count,
            direction: .forward
        )
    }

    func findPrevious() {
        currentMatchIndex = SearchNavigator.advance(
            from: currentMatchIndex,
            matchCount: matches.count,
            direction: .backward
        )
    }

    func presentFind() {
        isFindPresented = true
        findFocusToken += 1
    }

    func dismissFind() {
        isFindPresented = false
        findQuery = ""
        matches = []
        currentMatchIndex = nil
    }

    func open() {
        guard confirmDiscardIfNeeded() else { return }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = Self.markdownTypes
        guard panel.runModal() == .OK, let url = panel.url else { return }
        open(url: url)
    }

    func open(url: URL) {
        do {
            document = try MarkdownDocument.load(from: url)
            previewMarkdown = document.text
            refreshMatches(resetSelection: true)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func save() -> Bool {
        if document.fileURL == nil {
            return saveAs()
        }
        do {
            try document.save()
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func saveAs() -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [Self.markdownTypes[0]]
        panel.nameFieldStringValue = document.displayName
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        do {
            try document.save(to: url)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func confirmDiscardIfNeeded() -> Bool {
        guard document.isDirty else { return true }
        let alert = NSAlert()
        alert.messageText = "Save changes to \(document.displayName)?"
        alert.informativeText = "Your edits will be lost if you don't save."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return save()
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }

    func consumeLaunchArgumentsIfNeeded() {
        let paths = CommandLine.arguments.dropFirst().filter { !$0.hasPrefix("-") }
        guard let path = paths.first else { return }
        open(url: URL(fileURLWithPath: path))
    }

    private func schedulePreview() {
        previewTask?.cancel()
        previewTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            previewMarkdown = document.text
        }
    }

    private static var markdownTypes: [UTType] {
        [
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText,
            .plainText,
        ]
    }
}
