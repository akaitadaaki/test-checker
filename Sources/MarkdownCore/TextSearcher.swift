import Foundation

public enum TextSearcher: Sendable {
    public static func findMatches(
        in text: String,
        query: String,
        caseSensitive: Bool = false
    ) -> [NSRange] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }

        let haystack = text as NSString
        var matches: [NSRange] = []
        var searchRange = NSRange(location: 0, length: haystack.length)
        let options: NSString.CompareOptions = caseSensitive ? [] : [.caseInsensitive]

        while searchRange.length > 0 {
            let found = haystack.range(of: needle, options: options, range: searchRange)
            guard found.location != NSNotFound else { break }
            matches.append(found)
            let nextLocation = found.location + max(found.length, 1)
            guard nextLocation <= haystack.length else { break }
            searchRange = NSRange(location: nextLocation, length: haystack.length - nextLocation)
        }

        return matches
    }
}

public enum SearchDirection: Sendable {
    case forward
    case backward
}

public enum SearchNavigator: Sendable {
    public static func advance(
        from current: Int?,
        matchCount: Int,
        direction: SearchDirection
    ) -> Int? {
        guard matchCount > 0 else { return nil }
        switch direction {
        case .forward:
            if let current {
                return (current + 1) % matchCount
            }
            return 0
        case .backward:
            if let current {
                return (current - 1 + matchCount) % matchCount
            }
            return matchCount - 1
        }
    }
}
