import Foundation
import Testing
@testable import MarkdownCore

struct MarkdownDocumentTests {
    @Test func untitledDocumentIsNotDirty() {
        let document = MarkdownDocument(text: "# hi")
        #expect(!document.isDirty)
    }

    @Test func editingMarksDocumentDirty() {
        var document = MarkdownDocument(text: "# hi")
        document.text = "# hello"
        #expect(document.isDirty)
    }

    @Test func loadThenEditThenSaveClearsDirty() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("md")
        try "# original".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        var document = try MarkdownDocument.load(from: url)
        document.text = "# changed"
        try document.save()

        #expect(!document.isDirty)
        #expect(try String(contentsOf: url, encoding: .utf8) == "# changed")
    }

    @Test func saveWithoutURLThrows() {
        var document = MarkdownDocument(text: "x")
        #expect(throws: MarkdownDocumentError.noFileURL) {
            try document.save()
        }
    }

    @Test func displayNameUsesFilename() {
        let url = URL(fileURLWithPath: "/tmp/readme.md")
        let document = MarkdownDocument(fileURL: url, text: "")
        #expect(document.displayName == "readme.md")
    }

    @Test func untitledDisplayName() {
        #expect(MarkdownDocument().displayName == "Untitled.md")
    }
}
