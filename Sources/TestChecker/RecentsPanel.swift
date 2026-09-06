import SwiftUI

struct RecentsPanel: View {
    @Environment(EditorSession.self) private var session

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1.2)
                .padding(.bottom, 18)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(session.recentFiles) { file in
                    Button {
                        session.openRecent(file.url)
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(file.url.lastPathComponent)
                                .font(.system(size: 16, weight: .medium, design: .serif))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer(minLength: 12)
                            Text(abbreviatedDirectory(for: file.url))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.head)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(Palette.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
            }

            HStack(spacing: 18) {
                Button("Open Other…") {
                    session.open()
                }
                Button("Blank Document") {
                    session.startBlankDocument()
                }
                Spacer()
            }
            .font(.system(size: 13, weight: .medium))
            .padding(.top, 22)
        }
        .padding(40)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.paneBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.copper)
                .frame(height: 1.5)
        }
    }

    private func abbreviatedDirectory(for url: URL) -> String {
        let directory = url.deletingLastPathComponent().path
        let home = NSHomeDirectory()
        if directory.hasPrefix(home) {
            return "~" + directory.dropFirst(home.count)
        }
        return directory
    }
}
