import Foundation
import Markdown

public enum PreviewSelection: Sendable {
    public static func visibleText(from markdown: String) -> String {
        decodeEntities(stripTags(HTMLFormatter.format(markdown)))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func stripTags(_ html: String) -> String {
        var result = ""
        result.reserveCapacity(html.count)
        var insideTag = false
        for character in html {
            if character == "<" {
                insideTag = true
                continue
            }
            if character == ">" {
                insideTag = false
                continue
            }
            if !insideTag {
                result.append(character)
            }
        }
        return result
    }

    static func decodeEntities(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }
}
