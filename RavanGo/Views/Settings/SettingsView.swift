import SwiftData
import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var preferences: PreferencesStore
    @Query private var scripts: [Script]

    @State private var showingImporter = false
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var alertMessage: String?

    var body: some View {
        Form {
            Section("Teleprompter") {
                SliderSettingRow(
                    title: "Default speed",
                    valueLabel: String(format: "%.2fx", preferences.values.defaultSpeed),
                    value: preferenceBinding(\.defaultSpeed),
                    range: 0.25...3.0,
                    step: 0.05
                )
                SliderSettingRow(
                    title: "Default font size",
                    valueLabel: "\(Int(preferences.values.defaultFontSize)) pt",
                    value: preferenceBinding(\.defaultFontSize),
                    range: 24...80,
                    step: 1
                )
                SliderSettingRow(
                    title: "Default line spacing",
                    valueLabel: "\(Int(preferences.values.defaultLineSpacing)) pt",
                    value: preferenceBinding(\.defaultLineSpacing),
                    range: 0...36,
                    step: 1
                )
                SliderSettingRow(
                    title: "Default margins",
                    valueLabel: "\(Int(preferences.values.defaultMargins)) pt",
                    value: preferenceBinding(\.defaultMargins),
                    range: 12...72,
                    step: 1
                )
                Picker("Countdown", selection: preferenceBinding(\.countdownDuration)) {
                    ForEach(CountdownDuration.allCases) { duration in
                        Text(duration.label).tag(duration)
                    }
                }
                Toggle("Mirror mode", isOn: preferenceBinding(\.mirrorMode))
                Toggle("Focus guide", isOn: preferenceBinding(\.focusGuide))
            }

            Section("Reading") {
                SliderSettingRow(
                    title: "Words per minute",
                    valueLabel: "\(Int(preferences.values.wordsPerMinute)) wpm",
                    value: preferenceBinding(\.wordsPerMinute),
                    range: 80...220,
                    step: 5
                )
            }

            Section("Appearance") {
                Picker("Color scheme", selection: preferenceBinding(\.appearance)) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.label).tag(appearance)
                    }
                }
            }

            Section("Language") {
                Picker("Language", selection: preferenceBinding(\.language)) {
                    Text("English").tag(AppLanguage.english)
                    Text("Persian").tag(AppLanguage.persian)
                }
            }

            Section("Data") {
                Button {
                    prepareExport()
                } label: {
                    Label("Export Scripts", systemImage: "square.and.arrow.up")
                }

                Button {
                    showingImporter = true
                } label: {
                    Label("Import Scripts", systemImage: "square.and.arrow.down")
                }
            }

            Section("About") {
                Text("RavanGo")
                    .font(.headline)
                Text("Created by Behnam Jalali")
                    .foregroundStyle(.secondary)
                LabeledContent("Version", value: appVersion)
                LabeledContent("Build", value: buildNumber)
                Text("All scripts and settings are stored locally on the user’s device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false,
            onCompletion: importFile
        )
        .sheet(isPresented: $showingShareSheet) {
            if let exportURL {
                ShareSheet(items: [exportURL as Any])
                    .ignoresSafeArea()
            }
        }
        .alert("Data", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .onChange(of: preferences.errorMessage) { _, message in
            guard let message else { return }
            alertMessage = message
            preferences.clearError()
        }
        .task {
            if let message = preferences.errorMessage {
                alertMessage = message
                preferences.clearError()
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    private func preferenceBinding<Value>(_ keyPath: WritableKeyPath<UserPreferences, Value>) -> Binding<Value> {
        Binding(
            get: { preferences.values[keyPath: keyPath] },
            set: { newValue in
                preferences.update { values in
                    values[keyPath: keyPath] = newValue
                }
            }
        )
    }

    private func prepareExport() {
        do {
            exportURL = try ImportExportService.exportURL(for: scripts)
            showingShareSheet = true
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func importFile(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result, let url = urls.first else { return }
        do {
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
            }
            let data = try Data(contentsOf: url)
            let count = try ImportExportService.importScripts(
                from: data,
                into: modelContext,
                existingScripts: scripts
            )
            alertMessage = String(localized: "Imported \(count) script.", locale: preferences.values.language.locale)
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(PreferencesStore(defaults: UserDefaults(suiteName: "SettingsPreview") ?? .standard))
    .modelContainer(for: Script.self, inMemory: true)
}
