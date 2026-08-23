import SwiftUI

@main
struct TestCheckerApp: App {
    @State private var session = EditorSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(session)
                .frame(minWidth: 720, minHeight: 480)
        }
        .defaultSize(width: 1100, height: 740)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open…") { session.open() }
                    .keyboardShortcut("o", modifiers: .command)
                Menu("Open Recent") {
                    RecentsMenuItems(session: session)
                }
                Button("Save") { _ = session.save() }
                    .keyboardShortcut("s", modifiers: .command)
                Button("Save As…") { _ = session.saveAs() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            CommandGroup(after: .textEditing) {
                Button("Find…") { session.presentFind() }
                    .keyboardShortcut("f", modifiers: .command)
                Button("Find Next") { session.findNext() }
                    .keyboardShortcut("g", modifiers: .command)
                    .disabled(!session.isFindPresented)
                Button("Find Previous") { session.findPrevious() }
                    .keyboardShortcut("g", modifiers: [.command, .shift])
                    .disabled(!session.isFindPresented)
            }
        }
    }
}
