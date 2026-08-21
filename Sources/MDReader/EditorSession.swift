import AppKit
import Foundation
import MarkdownCore
import Observation
import UniformTypeIdentifiers

enum PaneScrollOrigin: Equatable {
    case none
    case editor
    case preview
}

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
    var recents = RecentFilesStore()
    var prefersRecentsPanel = true
    var visibleSourceLine = 1
    var previewSelectRaw = ""
    var previewSelectVisible = ""
    var previewSelectToken = 0
    var scrollOrigin: PaneScrollOrigin = .none

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
    private var scrollOriginResetTask: Task<Void, Never>?
    private let defaults: UserDefaults

    static let recentsDefaultsKey = "mdreader.recentFilePaths"

    var recentFiles: [RecentFile] {
        recents.files()
    }

    var showsRecentsPanel: Bool {
        prefersRecentsPanel && document.fileURL == nil && document.text.isEmpty && !recentFiles.isEmpty
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        recents = Self.loadRecents(from: defaults)
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
        publishCurrentMatchSelection()
    }

    func findNext() {
        currentMatchIndex = SearchNavigator.advance(
            from: currentMatchIndex,
            matchCount: matches.count,
            direction: .forward
        )
        publishCurrentMatchSelection()
    }

    func findPrevious() {
        currentMatchIndex = SearchNavigator.advance(
            from: currentMatchIndex,
            matchCount: matches.count,
            direction: .backward
        )
        publishCurrentMatchSelection()
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
        editorDidSelect(NSRange(location: 0, length: 0))
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
            visibleSourceLine = 1
            scrollOrigin = .none
            refreshMatches(resetSelection: true)
            prefersRecentsPanel = false
            errorMessage = nil
            remember(url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openRecent(_ url: URL) {
        guard confirmDiscardIfNeeded() else { return }
        open(url: url)
    }

    func startBlankDocument() {
        prefersRecentsPanel = false
    }

    func clearRecents() {
        recents.clear()
        persistRecents()
    }

    @discardableResult
    func save() -> Bool {
        if document.fileURL == nil {
            return saveAs()
        }
        do {
            try document.save()
            errorMessage = nil
            rememberCurrentFile()
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
            remember(url)
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

    func editorDidScroll(to line: Int) {
        guard scrollOrigin != .preview else { return }
        guard line != visibleSourceLine else { return }
        scrollOrigin = .editor
        visibleSourceLine = line
        resetScrollOriginLater()
    }

    func previewDidScroll(to line: Int) {
        guard scrollOrigin != .editor else { return }
        guard line != visibleSourceLine else { return }
        scrollOrigin = .preview
        visibleSourceLine = line
        resetScrollOriginLater()
    }

    func editorDidSelect(_ range: NSRange) {
        let ns = document.text as NSString
        guard range.length > 0, NSMaxRange(range) <= ns.length else {
            if !previewSelectRaw.isEmpty || !previewSelectVisible.isEmpty {
                previewSelectRaw = ""
                previewSelectVisible = ""
                previewSelectToken += 1
            }
            return
        }
        var raw = ns.substring(with: range)
        if raw.count > 4000 {
            raw = String(raw.prefix(4000))
        }
        previewSelectRaw = raw
        previewSelectVisible = PreviewSelection.visibleText(from: raw)
        previewSelectToken += 1
    }

    private func publishCurrentMatchSelection() {
        guard let currentMatchIndex, matches.indices.contains(currentMatchIndex) else { return }
        editorDidSelect(matches[currentMatchIndex])
    }

    private func resetScrollOriginLater() {
        scrollOriginResetTask?.cancel()
        scrollOriginResetTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }
            scrollOrigin = .none
        }
    }

    private func schedulePreview() {
        previewTask?.cancel()
        previewTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            previewMarkdown = document.text
        }
    }

    private func rememberCurrentFile() {
        guard let url = document.fileURL else { return }
        remember(url)
    }

    private func remember(_ url: URL) {
        recents.record(url)
        persistRecents()
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
    }

    private func persistRecents() {
        guard let data = try? recents.json() else { return }
        defaults.set(data, forKey: Self.recentsDefaultsKey)
    }

    private static func loadRecents(from defaults: UserDefaults) -> RecentFilesStore {
        guard let data = defaults.data(forKey: recentsDefaultsKey),
              var store = try? RecentFilesStore.load(from: data)
        else {
            return RecentFilesStore()
        }
        store.pruneMissing()
        return store
    }

    private static var markdownTypes: [UTType] {
        [
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText,
            .plainText,
        ]
    }
}
