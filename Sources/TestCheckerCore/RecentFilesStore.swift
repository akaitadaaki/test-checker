import Foundation

public struct RecentFile: Equatable, Sendable, Identifiable {
    public let url: URL
    public var id: String { url.standardizedFileURL.path }

    public init(url: URL) {
        self.url = url
    }

    public var menuTitle: String {
        let name = url.lastPathComponent
        let parent = url.deletingLastPathComponent().lastPathComponent
        if parent.isEmpty || parent == "/" {
            return name
        }
        return "\(name) — \(parent)"
    }
}

public struct RecentFilesStore: Equatable, Sendable {
    public private(set) var paths: [String]
    public let limit: Int

    public init(paths: [String] = [], limit: Int = 12) {
        self.limit = max(1, limit)
        self.paths = Array(paths.prefix(self.limit))
    }

    public mutating func record(
        _ url: URL,
        fileExists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
    ) {
        pruneMissing(fileExists: fileExists)
        let path = Self.normalizedPath(url)
        paths.removeAll { $0 == path }
        paths.insert(path, at: 0)
        if paths.count > limit {
            paths = Array(paths.prefix(limit))
        }
    }

    public mutating func clear() {
        paths = []
    }

    public func files(
        fileExists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
    ) -> [RecentFile] {
        paths.filter(fileExists).map { RecentFile(url: URL(fileURLWithPath: $0)) }
    }

    public func json() throws -> Data {
        try JSONEncoder().encode(paths)
    }

    public static func load(from data: Data, limit: Int = 12) throws -> RecentFilesStore {
        let paths = try JSONDecoder().decode([String].self, from: data)
        return RecentFilesStore(paths: paths, limit: limit)
    }

    public mutating func pruneMissing(
        fileExists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
    ) {
        paths.removeAll { !fileExists($0) }
    }

    private static func normalizedPath(_ url: URL) -> String {
        url.standardizedFileURL.path
    }
}
