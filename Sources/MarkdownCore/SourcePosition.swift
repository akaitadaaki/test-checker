import Foundation

public enum SourcePosition: Sendable {
    public static func line(atUTF16Offset offset: Int, in text: String) -> Int {
        let ns = text as NSString
        guard ns.length > 0 else { return 1 }
        let clamped = max(0, min(offset, ns.length))
        var currentLine = 1
        var location = 0
        while location < clamped {
            let range = ns.lineRange(for: NSRange(location: location, length: 0))
            let next = range.location + range.length
            if clamped < next {
                return currentLine
            }
            if clamped == next {
                return next < ns.length ? currentLine + 1 : currentLine
            }
            location = next
            currentLine += 1
            if range.length == 0 { break }
        }
        return currentLine
    }

    public static func utf16Offset(ofLine line: Int, in text: String) -> Int {
        let ns = text as NSString
        guard line > 1, ns.length > 0 else { return 0 }
        var currentLine = 1
        var location = 0
        while currentLine < line, location < ns.length {
            let range = ns.lineRange(for: NSRange(location: location, length: 0))
            location = range.location + range.length
            currentLine += 1
            if range.length == 0 { break }
        }
        return min(location, ns.length)
    }
}
