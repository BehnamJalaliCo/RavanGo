import SwiftUI
import SwiftData
import UIKit

@MainActor
struct TeleprompterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.layoutDirection) private var appLayoutDirection
    @EnvironmentObject private var preferences: PreferencesStore
    @StateObject private var viewModel: TeleprompterViewModel

    @State private var showingSpeedSheet = false
    @State private var showingTextSheet = false
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var viewportHeight: CGFloat = 600
    @State private var previousIdleTimerDisabled = false

    init(script: Script, preferences: PreferencesStore) {
        _viewModel = StateObject(wrappedValue: TeleprompterViewModel(
            script: script,
            preferences: preferences
        ))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                viewModel.backgroundColor.color
                    .ignoresSafeArea()

                TeleprompterScrollView(
                    text: viewModel.script.content,
                    fontSize: viewModel.fontSize,
                    lineSpacing: viewModel.lineSpacing,
                    margins: viewModel.margins,
                    font: viewModel.font,
                    alignment: viewModel.textAlignment,
                    textColor: viewModel.textColor,
                    mirrored: viewModel.mirrorMode,
                    isPlaying: viewModel.isPlaying,
                    speed: viewModel.speed,
                    restartToken: viewModel.restartToken,
                    pendingSeek: viewModel.pendingSeek,
                    viewportHeight: viewportHeight,
                    layoutDirection: viewModel.scriptDirection.resolvedLayoutDirection(
                        for: viewModel.script.content,
                        fallback: appLayoutDirection
                    ),
                    onUserPause: {
                        viewModel.pause()
                    },
                    onSeekConsumed: {
                        viewModel.pendingSeek = 0
                    }
                )

                if viewModel.focusGuide {
                    FocusGuideView(position: viewModel.focusGuidePosition)
                }

                if let remaining = viewModel.countdownRemaining {
                    Text("\(remaining)")
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.textColor.color)
                        .transition(.opacity)
                        .accessibilityLabel("Countdown \(remaining)")
                }

                if viewModel.controlsVisible {
                    VStack {
                        TeleprompterControlsView(
                            viewModel: viewModel,
                            onClose: { dismiss() },
                            onSpeed: { showingSpeedSheet = true },
                            onText: { showingTextSheet = true }
                        )
                        Spacer()
                    }
                    .transition(.opacity)
                }

                if viewModel.isLocked && !viewModel.controlsVisible {
                    VStack {
                        Spacer()
                        Button {
                            viewModel.unlock()
                            viewModel.controlsVisible = true
                            scheduleControlsHide()
                        } label: {
                            Label("Unlock controls", systemImage: "lock.open")
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        .padding(.bottom, 24)
                    }
                }

                RemoteCommandView { command in
                    viewModel.handleRemoteCommand(command)
                    scheduleControlsHide()
                }
                .frame(width: 1, height: 1)
                .opacity(0.01)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture(count: 2)
                    .exclusively(before: TapGesture())
                    .onEnded { result in
                        switch result {
                        case .first:
                            viewModel.togglePlayback()
                            scheduleControlsHide()
                        case .second:
                            viewModel.controlsVisible.toggle()
                            if viewModel.controlsVisible {
                                scheduleControlsHide()
                            }
                        }
                    }
            )
            .onAppear {
                viewportHeight = proxy.size.height
                previousIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
                UIApplication.shared.isIdleTimerDisabled = true
                scheduleControlsHide()
            }
            .onChange(of: proxy.size.height) { _, height in
                viewportHeight = height
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = previousIdleTimerDisabled
                hideControlsTask?.cancel()
                viewModel.persistCurrentSettings()
                do {
                    try ScriptStorageService.save(modelContext)
                } catch {
                    viewModel.preferenceErrorMessage = String(
                        localized: "RavanGo could not save this script.",
                        locale: preferences.values.language.locale
                    )
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    UIApplication.shared.isIdleTimerDisabled = true
                } else {
                    UIApplication.shared.isIdleTimerDisabled = previousIdleTimerDisabled
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden(true)
        .sheet(isPresented: $showingSpeedSheet) {
            TeleprompterSpeedSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingTextSheet) {
            TeleprompterTextSettingsSheet(viewModel: viewModel)
        }
        .alert("Settings Error", isPresented: Binding(
            get: { viewModel.preferenceErrorMessage != nil },
            set: { if !$0 { viewModel.preferenceErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                viewModel.preferenceErrorMessage
                    ?? String(
                        localized: "RavanGo could not save these settings.",
                        locale: preferences.values.language.locale
                    )
            )
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.controlsVisible)
    }

    private func scheduleControlsHide() {
        hideControlsTask?.cancel()
        viewModel.controlsVisible = true
        hideControlsTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 3_000_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            viewModel.controlsVisible = false
        }
    }
}

private struct FocusGuideView: View {
    let position: Double

    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(.white.opacity(0.16))
                .frame(height: 2)
                .position(x: proxy.size.width / 2, y: proxy.size.height * position)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        TeleprompterView(
            script: Script(
                title: "Welcome",
                content: "This is a realistic teleprompter preview.\n\nThe reading area stays dominant while controls remain available with one tap.\n\nUse the speed and text controls to adjust the experience for your voice and setup."
            ),
            preferences: PreferencesStore(
                defaults: UserDefaults(suiteName: "TeleprompterPreview") ?? .standard
            )
        )
    }
    .environmentObject(
        PreferencesStore(
            defaults: UserDefaults(suiteName: "TeleprompterPreviewEnvironment") ?? .standard
        )
    )
    .modelContainer(for: Script.self, inMemory: true)
}
