import SwiftUI

@MainActor
struct TeleprompterControlsView: View {
    @ObservedObject var viewModel: TeleprompterViewModel
    @Environment(\.layoutDirection) private var appLayoutDirection
    let onClose: () -> Void
    let onSpeed: () -> Void
    let onText: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close teleprompter")
                Image(systemName: "text.book.closed")
                    .foregroundStyle(.secondary)
                titleView
                Spacer()
                Button {
                    viewModel.toggleLock()
                } label: {
                    Image(systemName: viewModel.isLocked ? "lock.fill" : "lock.open")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(lockAccessibilityLabel)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Spacer()

            HStack(spacing: 10) {
                controlButton("arrow.counterclockwise", title: "Restart") {
                    viewModel.restart()
                }
                controlButton(viewModel.isPlaying ? "pause.fill" : "play.fill", title: playbackTitle) {
                    viewModel.togglePlayback()
                }
                controlButton("speedometer", title: "Speed") {
                    onSpeed()
                }
                .disabled(viewModel.isLocked)
                controlButton("textformat.size", title: "Text") {
                    onText()
                }
                .disabled(viewModel.isLocked)
                controlButton(
                    viewModel.mirrorMode
                        ? "rectangle.lefthalf.inset.filled.arrow.left"
                        : "rectangle.lefthalf.inset.filled.arrow.right",
                    title: "Mirror"
                ) {
                    guard !viewModel.isLocked else { return }
                    viewModel.mirrorMode.toggle()
                    viewModel.persistCurrentSettings()
                }
                .disabled(viewModel.isLocked)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .foregroundStyle(.primary)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.12))
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .frame(maxHeight: 180)
        .accessibilityElement(children: .contain)
    }

    private func controlButton(
        _ systemImage: String,
        title: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .ravanGoFont(.headline)
                    .frame(width: 44, height: 32)
                Text(title)
                    .ravanGoFont(.caption2)
            }
            .frame(minWidth: 48)
        }
        .accessibilityLabel(title)
    }

    private var playbackTitle: LocalizedStringKey {
        viewModel.isPlaying ? "Pause" : "Play"
    }

    private var lockAccessibilityLabel: LocalizedStringKey {
        viewModel.isLocked ? "Unlock controls" : "Lock controls"
    }

    @ViewBuilder
    private var titleView: some View {
        if viewModel.script.title.isEmpty {
            Text("Untitled Script")
                .ravanGoFont(.headline, weight: .semibold)
                .lineLimit(1)
                .environment(\.layoutDirection, viewModel.script.resolvedTitleLayoutDirection(fallback: appLayoutDirection))
        } else {
            Text(viewModel.script.title)
                .ravanGoFont(.headline, weight: .semibold)
                .lineLimit(1)
                .environment(\.layoutDirection, viewModel.script.resolvedTitleLayoutDirection(fallback: appLayoutDirection))
        }
    }
}
