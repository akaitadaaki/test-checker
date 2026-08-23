import Foundation

public enum MarkdownDocumentError: Error, Equatable, Sendable {
    case noFileURL
}

public struct MarkdownDocument: Equatable, Sendable {
    public var fileURL: URL?
    public var text: String
    public private(set) var savedText: String

    public init(fileURL: URL? = nil, text: String = "") {
        self.fileURL = fileURL
        self.text = text
        self.savedText = text
    }

    public var isDirty: Bool { text != savedText }

    public var displayName: String {
        fileURL?.lastPathComponent ?? "Untitled.md"
    }

    public static func load(from url: URL) throws -> MarkdownDocument {
        let text = try String(contentsOf: url, encoding: .utf8)
        return MarkdownDocument(fileURL: url, text: text)
    }

    public mutating func save(to url: URL? = nil) throws {
        let target = url ?? fileURL
        guard let target else { throw MarkdownDocumentError.noFileURL }
        try text.write(to: target, atomically: true, encoding: .utf8)
        fileURL = target
        savedText = text
    }
}
