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

            if session.showsRecentsPanel {
                RecentsPanel()
            } else {
                HSplitView {
                    ChecklistPane()
                        .frame(minWidth: 300, idealWidth: 380, maxWidth: 640, maxHeight: .infinity)

                    // エディタとプレビューは入れ子の分割ビューにまとめる。
                    // 出し入れによる幅の再配分をこのグループ内に閉じ込め、
                    // エディタを隠すとプレビューが元の幅に戻るようにするため。
                    HSplitView {
                        if session.showsEditor {
                            SourceEditorView(
                                text: $session.document.text,
                                matches: session.matches,
                                currentMatchIndex: session.currentMatchIndex,
                                visibleLine: session.visibleSourceLine,
                                followPreviewScroll: session.scrollOrigin == .preview || session.scrollOrigin == .checklist,
                                onVisibleLineChange: { session.editorDidScroll(to: $0) },
                                onSelectionChange: { session.editorDidSelect($0) }
                            )
                            .frame(minWidth: 260, maxWidth: .infinity, maxHeight: .infinity)
                        }

                        PreviewView(
                            html: session.previewHTML,
                            baseURL: session.previewBaseURL,
                            visibleLine: session.visibleSourceLine,
                            selectRaw: session.previewSelectRaw,
                            selectVisible: session.previewSelectVisible,
                            selectToken: session.previewSelectToken,
                            statusesJSON: session.previewStatusesJSON,
                            followEditorScroll: session.scrollOrigin == .editor || session.scrollOrigin == .checklist,
                            onVisibleLineChange: { session.previewDidScroll(to: $0) }
                        )
                        .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(Palette.paneBackground)
        .navigationTitle(session.windowTitle)
        .toolbar {
            ToolbarItemGroup {
                Toggle(isOn: $session.showsEditor) {
                    Label("エディタを表示/非表示", systemImage: "square.and.pencil")
                }
                .help(session.showsEditor ? "編集エリアを隠す" : "編集エリアを表示する")
                Menu {
                    RecentsMenuItems(session: session)
                } label: {
                    Text("Open")
                } primaryAction: {
                    session.open()
                }
                Button("Save") { _ = session.save() }
                Button("New Run") { session.startNewRun() }
                    .disabled(session.document.fileURL == nil)
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
