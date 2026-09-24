import SwiftUI

struct ScriptRowView: View {
    let script: Script
    @Environment(\.layoutDirection) private var appLayoutDirection

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                titleView
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(script.updatedAt, format: .relative(presentation: .named))
                    .ravanGoFont(.caption)
                    .foregroundStyle(.secondary)
            }
            contentView
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var titleView: some View {
        if script.title.isEmpty {
            Text("Untitled Script")
                .ravanGoFont(.headline, weight: .semibold)
                .environment(\.layoutDirection, script.resolvedTitleLayoutDirection(fallback: appLayoutDirection))
        } else {
            Text(script.title)
                .ravanGoFont(.headline, weight: .semibold)
                .environment(\.layoutDirection, script.resolvedTitleLayoutDirection(fallback: appLayoutDirection))
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if script.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text("No text yet")
                .ravanGoFont(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        } else {
            Text(script.previewText)
                .ravanGoFont(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .environment(\.layoutDirection, script.resolvedContentLayoutDirection(fallback: appLayoutDirection))
        }
    }
}

#Preview {
    ScriptRowView(script: Script(title: "Welcome", content: "A short script preview for the library."))
        .padding()
}
