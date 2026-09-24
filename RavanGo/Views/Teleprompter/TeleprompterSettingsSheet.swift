import SwiftUI

@MainActor
struct TeleprompterSpeedSheet: View {
    @ObservedObject var viewModel: TeleprompterViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var preferences: PreferencesStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Presets") {
                    Picker("Preset", selection: Binding(
                        get: { closestPreset },
                        set: { viewModel.setPreset($0) }
                    )) {
                        ForEach(SpeedPreset.allCases) { preset in
                            Text(preset.label).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Fine adjustment") {
                    SliderSettingRow(
                        title: "Speed",
                        valueLabel: AppFormatting.speed(viewModel.speed, language: preferences.values.language),
                        value: $viewModel.speed,
                        range: 0.25...3.0,
                        step: 0.05
                    )
                }
            }
            .navigationTitle("Scroll Speed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.persistCurrentSettings()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var closestPreset: SpeedPreset {
        SpeedPreset.allCases.min {
            abs($0.multiplier - viewModel.speed) < abs($1.multiplier - viewModel.speed)
        } ?? .normal
    }
}

@MainActor
struct TeleprompterTextSettingsSheet: View {
    @ObservedObject var viewModel: TeleprompterViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var preferences: PreferencesStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Text") {
                    SliderSettingRow(
                        title: "Font size",
                        valueLabel: AppFormatting.points(viewModel.fontSize, language: preferences.values.language),
                        value: $viewModel.fontSize,
                        range: 24...80,
                        step: 1
                    )
                    SliderSettingRow(
                        title: "Line spacing",
                        valueLabel: AppFormatting.points(viewModel.lineSpacing, language: preferences.values.language),
                        value: $viewModel.lineSpacing,
                        range: 0...36,
                        step: 1
                    )
                    SliderSettingRow(
                        title: "Side margins",
                        valueLabel: AppFormatting.points(viewModel.margins, language: preferences.values.language),
                        value: $viewModel.margins,
                        range: 12...72,
                        step: 1
                    )
                }

                Section("Style") {
                    Picker("Font", selection: $viewModel.font) {
                        ForEach(TeleprompterFont.allCases) { font in
                            Text(font.label).tag(font)
                        }
                    }
                    Picker("Alignment", selection: $viewModel.textAlignment) {
                        ForEach(TextAlignmentOption.allCases) { alignment in
                            Text(alignment.label).tag(alignment)
                        }
                    }
                    Picker("Text Direction", selection: $viewModel.scriptDirection) {
                        ForEach(ScriptDirection.allCases) { direction in
                            Text(direction.label).tag(direction)
                        }
                    }
                    Picker("Text color", selection: $viewModel.textColor) {
                        ForEach(TextColorOption.allCases) { color in
                            Text(color.label).tag(color)
                        }
                    }
                    Picker("Background", selection: $viewModel.backgroundColor) {
                        ForEach(BackgroundColorOption.allCases) { color in
                            Text(color.label).tag(color)
                        }
                    }
                }

                Section("Reading guide") {
                    Toggle("Focus guide", isOn: $viewModel.focusGuide)
                    if viewModel.focusGuide {
                        SliderSettingRow(
                            title: "Vertical position",
                            valueLabel: AppFormatting.percentage(
                                viewModel.focusGuidePosition,
                                language: preferences.values.language
                            ),
                            value: $viewModel.focusGuidePosition,
                            range: 0.3...0.7,
                            step: 0.05
                        )
                    }
                }
            }
            .navigationTitle("Text Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.persistCurrentSettings()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}
