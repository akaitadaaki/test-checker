import SwiftUI

struct ContentView: View {
    @Environment(EditorSession.self) private var session
    @State private var didConsumeLaunchArguments = false

    var body: some View {
        @Bindable var session = session

        VStack(spacing: 0) {
            if session.isFindPresented {
                FindBar()
            }

            HSplitView {
                SourceEditorView(
                    text: $session.document.text,
                    matches: session.matches,
                    currentMatchIndex: session.currentMatchIndex
                )
                .frame(minWidth: 260)

                PreviewView(html: session.previewHTML, baseURL: session.previewBaseURL)
                    .frame(minWidth: 300)
            }
        }
        .background(Palette.chrome)
        .navigationTitle(session.windowTitle)
        .toolbar {
            ToolbarItemGroup {
                Button("Open") { session.open() }
                Button("Save") { _ = session.save() }
            }
        }
        .onChange(of: session.document.text) { _, _ in
            session.documentTextDidChange()
        }
        .onAppear {
            guard !didConsumeLaunchArguments else { return }
            didConsumeLaunchArguments = true
            session.consumeLaunchArgumentsIfNeeded()
        }
        .onOpenURL { url in
            guard session.confirmDiscardIfNeeded() else { return }
            session.open(url: url)
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first, session.confirmDiscardIfNeeded() else { return false }
            session.open(url: url)
            return true
        }
        .alert(
            "Couldn't read file",
            isPresented: Binding(
                get: { session.errorMessage != nil },
                set: { if !$0 { session.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { session.errorMessage = nil }
        } message: {
            Text(session.errorMessage ?? "")
        }
    }
}
