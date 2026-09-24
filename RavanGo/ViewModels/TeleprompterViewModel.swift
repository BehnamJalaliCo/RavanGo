import Foundation
import SwiftUI

@MainActor
final class TeleprompterViewModel: ObservableObject {
    let script: Script

    @Published var speed: Double
    @Published var fontSize: Double
    @Published var lineSpacing: Double
    @Published var margins: Double
    @Published var mirrorMode: Bool
    @Published var focusGuide: Bool
    @Published var focusGuidePosition: Double
    @Published var font: TeleprompterFont
    @Published var textAlignment: TextAlignmentOption
    @Published var textColor: TextColorOption
    @Published var backgroundColor: BackgroundColorOption
    @Published var scriptDirection: ScriptDirection
    @Published private(set) var isPlaying = false
    @Published private(set) var hasStarted = false
    @Published private(set) var isLocked = false
    @Published private(set) var countdownRemaining: Int?
    @Published var preferenceErrorMessage: String? = nil
    @Published var controlsVisible = true

    @Published private(set) var restartToken = 0
    private var countdownTask: Task<Void, Never>?
    private let preferences: PreferencesStore

    init(script: Script, preferences: PreferencesStore) {
        self.script = script
        self.preferences = preferences
        let values = preferences.values
        speed = values.defaultSpeed
        fontSize = values.defaultFontSize
        lineSpacing = values.defaultLineSpacing
        margins = values.defaultMargins
        mirrorMode = values.mirrorMode
        focusGuide = values.focusGuide
        focusGuidePosition = values.focusGuidePosition
        font = values.font
        textAlignment = values.textAlignment
        textColor = values.textColor
        backgroundColor = values.backgroundColor
        scriptDirection = script.direction
    }

    deinit {
        countdownTask?.cancel()
    }

    var countdownDuration: CountdownDuration {
        preferences.values.countdownDuration
    }

    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            start()
        }
    }

    func start() {
        guard !isPlaying else { return }
        if !hasStarted, countdownDuration != .off {
            beginCountdown()
        } else {
            beginPlayback()
        }
    }

    func pause() {
        countdownTask?.cancel()
        countdownTask = nil
        countdownRemaining = nil
        isPlaying = false
        Haptics.light()
    }

    func restart() {
        countdownTask?.cancel()
        countdownTask = nil
        countdownRemaining = nil
        isPlaying = false
        hasStarted = false
        restartToken += 1
        Haptics.medium()
        start()
    }

    func toggleLock() {
        isLocked.toggle()
        Haptics.medium()
    }

    func unlock() {
        guard isLocked else { return }
        isLocked = false
        Haptics.medium()
    }

    func setPreset(_ preset: SpeedPreset) {
        guard !isLocked else { return }
        speed = preset.multiplier
        Haptics.selection()
    }

    func handleRemoteCommand(_ command: RemoteCommand) {
        guard !isLocked || command == .togglePlayback else { return }
        switch command {
        case .togglePlayback: togglePlayback()
        case .decreaseSpeed: speed = max(AppConstants.speedRange.lowerBound, speed - 0.25)
        case .increaseSpeed: speed = min(AppConstants.speedRange.upperBound, speed + 0.25)
        case .moveBackward: seek(by: -300)
        case .moveForward: seek(by: 300)
        case .restart: restart()
        }
    }

    func markControlsInteraction() {
        controlsVisible = true
    }

    func persistCurrentSettings() {
        script.direction = scriptDirection
        preferences.update { values in
            values.defaultSpeed = speed
            values.defaultFontSize = fontSize
            values.defaultLineSpacing = lineSpacing
            values.defaultMargins = margins
            values.mirrorMode = mirrorMode
            values.focusGuide = focusGuide
            values.focusGuidePosition = focusGuidePosition
            values.font = font
            values.textAlignment = textAlignment
            values.textColor = textColor
            values.backgroundColor = backgroundColor
        }
        if let errorMessage = preferences.errorMessage {
            preferenceErrorMessage = errorMessage
            preferences.clearError()
        }
    }

    func seek(by points: CGFloat) {
        // The scroll view owns the exact offset. This value is consumed by the
        // view as a small relative movement request.
        pendingSeek += points
    }

    @Published var pendingSeek: CGFloat = 0

    private func beginCountdown() {
        countdownTask?.cancel()
        let duration = countdownDuration.rawValue
        countdownTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for value in stride(from: duration, through: 1, by: -1) {
                guard !Task.isCancelled else { return }
                countdownRemaining = value
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }
            }
            guard !Task.isCancelled else { return }
            countdownRemaining = nil
            beginPlayback()
        }
    }

    private func beginPlayback() {
        hasStarted = true
        isPlaying = true
        Haptics.light()
    }
}

enum SpeedPreset: CaseIterable, Identifiable {
    case slow
    case normal
    case fast

    var id: String { String(describing: self) }

    var label: LocalizedStringKey {
        switch self {
        case .slow: "Slow"
        case .normal: "Normal"
        case .fast: "Fast"
        }
    }

    var multiplier: Double {
        switch self {
        case .slow: 0.65
        case .normal: 1.0
        case .fast: 1.6
        }
    }
}
