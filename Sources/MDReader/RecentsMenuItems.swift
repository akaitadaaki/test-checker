import SwiftUI

struct RecentsMenuItems: View {
    var session: EditorSession

    var body: some View {
        if session.recentFiles.isEmpty {
            Text("No Recent Files")
        } else {
            ForEach(session.recentFiles) { file in
                Button(file.menuTitle) {
                    session.openRecent(file.url)
                }
            }
            Divider()
            Button("Clear Recents") {
                session.clearRecents()
            }
        }
    }
}
