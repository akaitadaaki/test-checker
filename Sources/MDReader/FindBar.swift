import SwiftUI

struct FindBar: View {
    @Environment(EditorSession.self) private var session
    @FocusState private var queryFocused: Bool

    var body: some View {
        @Bindable var session = session

        HStack(spacing: 10) {
            Text("Find")
                .font(.system(size: 10, weight: .semibold, design: .serif))
                .foregroundStyle(Palette.mutedInk)
                .textCase(.uppercase)
                .tracking(1.1)

            TextField("Search in this file", text: $session.findQuery)
                .textFieldStyle(.plain)
                .foregroundStyle(Palette.editorInk)
                .focused($queryFocused)
                .onSubmit { session.findNext() }
                .onChange(of: session.findQuery) { _, _ in
                    session.findQueryDidChange()
                }

            Text(session.matchLabel)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(session.hasFindQuery && session.matches.isEmpty ? Palette.copper : Palette.mutedInk)
                .frame(minWidth: 52, alignment: .trailing)

            Button {
                session.findPrevious()
            } label: {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.editorInk)
            .help("Previous match")

            Button {
                session.findNext()
            } label: {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.editorInk)
            .help("Next match")

            Toggle("Aa", isOn: $session.isCaseSensitive)
                .toggleStyle(.button)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .help("Case sensitive")
                .onChange(of: session.isCaseSensitive) { _, _ in
                    session.findQueryDidChange()
                }

            Button("Done") {
                session.dismissFind()
            }
            .font(.system(size: 11, weight: .medium))
            .buttonStyle(.plain)
            .foregroundStyle(Palette.mutedInk)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Palette.findRail)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Palette.copper)
                .frame(height: 1.5)
        }
        .onAppear { queryFocused = true }
        .onChange(of: session.findFocusToken) { _, _ in
            queryFocused = true
        }
        .onExitCommand { session.dismissFind() }
        .background {
            Button("Find Previous") { session.findPrevious() }
                .keyboardShortcut(.return, modifiers: .shift)
                .hidden()
        }
    }
}
