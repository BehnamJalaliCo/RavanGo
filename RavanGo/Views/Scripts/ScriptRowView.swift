import SwiftUI

struct ScriptRowView: View {
    let script: Script

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(script.title.isEmpty ? "Untitled Script" : script.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(script.updatedAt, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if script.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("No text yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                Text(script.previewText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .environment(\.layoutDirection, script.resolvedLayoutDirection)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(script.title), \(script.previewText)")
    }
}

#Preview {
    ScriptRowView(script: Script(title: "Welcome", content: "A short script preview for the library."))
        .padding()
}
