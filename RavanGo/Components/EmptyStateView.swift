import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "doc.text")
        } description: {
            Text(message)
        } actions: {
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    EmptyStateView(
        title: "No Scripts Yet",
        message: "Create your first script to begin.",
        actionTitle: "Create Script",
        action: {}
    )
}
