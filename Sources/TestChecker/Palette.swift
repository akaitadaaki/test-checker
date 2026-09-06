import SwiftUI

enum Palette {
    static let slate = Color(red: 0.102, green: 0.133, blue: 0.165)
    static let editorInk = Color(red: 0.82, green: 0.86, blue: 0.90)
    static let paper = Color(red: 0.949, green: 0.957, blue: 0.969)
    static let chrome = Color(red: 0.91, green: 0.922, blue: 0.937)
    static let findRail = Color(red: 0.125, green: 0.157, blue: 0.188)
    static let mutedInk = Color(red: 0.62, green: 0.69, blue: 0.74)
    static let copper = Color(red: 0.78, green: 0.38, blue: 0.18)
    static let pool = Color(red: 0.24, green: 0.49, blue: 0.56)

    // ライト/ダークに追従する背景色。固定色はダークモードで文字色(自動反転)と衝突するため、
    // ペインの背景には必ずこちらを使う。
    static let paneBackground = Color(nsColor: .windowBackgroundColor)
    static let cardBackground = Color(nsColor: .controlBackgroundColor)
}
