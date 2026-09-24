import Foundation
import SwiftData
import SwiftUI

@MainActor
struct ScriptEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var preferences: PreferencesStore
    @Bindable var script: Script

    @FocusState private var editorFocused: Bool
    @State private var showingClearConfirmation = false
    @State private var showingEmptyScriptAlert = false
    @State private var showingTeleprompter = false
    @StateObject private var autosave = ScriptAutosaveCoordinator()

    var body: some View {
        Form {
            Section {
                TextField("Script title", text: $script.title)
                    .font(.title3.weight(.semibold))
                    .textInputAutocapitalization(.sentences)
                    .accessibilityLabel("Script title")
                    .environment(\.layoutDirection, script.resolvedLayoutDirection)

                TextEditor(text: $script.content)
                    .focused($editorFocused)
                    .frame(minHeight: 300)
                    .font(.body)
                    .textInputAutocapitalization(.sentences)
                    .accessibilityLabel("Script text")
                    .environment(\.layoutDirection, script.resolvedLayoutDirection)
            }

            Section {
                LabeledContent("Words", value: "\(ScriptMetrics.wordCount(in: script.content))")
                LabeledContent(
                    "Estimated time",
                    value: ScriptMetrics.formattedDuration(
                        for: script.content,
                        wordsPerMinute: preferences.values.wordsPerMinute,
                        language: preferences.values.language
                    )
                )
            } header: {
                Text("Reading estimate")
            }

            Section {
                Button {
                    guard !script.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        showingEmptyScriptAlert = true
                        return
                    }
                    guard save() else { return }
                    editorFocused = false
                    showingTeleprompter = true
                } label: {
                    Label("Start Teleprompter", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityHint("Opens the teleprompter for this script")

                Button("Clear Text", role: .destructive) {
                    showingClearConfirmation = true
                }
            }
        }
        .navigationTitle(script.title.isEmpty ? "Untitled Script" : script.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    if save() {
                        dismiss()
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showingTeleprompter) {
            TeleprompterView(script: script, preferences: preferences)
        }
        .confirmationDialog(
            "Clear all text?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Text", role: .destructive) {
                script.content = ""
                script.updatedAt = .now
                save()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Add Some Text First", isPresented: $showingEmptyScriptAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The teleprompter needs a script before it can start.")
        }
        .alert("Storage Error", isPresented: Binding(
            get: { autosave.errorMessage != nil },
            set: { if !$0 { autosave.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(autosave.errorMessage ?? "RavanGo could not save this script.")
        }
        .onChange(of: script.title) { _, _ in
            script.updatedAt = .now
            scheduleSave()
        }
        .onChange(of: script.content) { _, _ in
            script.updatedAt = .now
            scheduleSave()
        }
        .onDisappear {
            autosave.cancel()
            save()
        }
    }

    @discardableResult
    private func save() -> Bool {
        script.updatedAt = .now
        do {
            try ScriptStorageService.save(modelContext)
            return true
        } catch {
            autosave.errorMessage = String(localized: "RavanGo could not save this script. Your last saved version was restored.")
            return false
        }
    }

    private func scheduleSave() {
        autosave.schedule(context: modelContext)
    }
}

@MainActor
private final class ScriptAutosaveCoordinator: ObservableObject {
    @Published var errorMessage: String? = nil

    private var task: Task<Void, Never>?

    func schedule(context: ModelContext) {
        task?.cancel()
        task = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 600_000_000)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            do {
                try ScriptStorageService.save(context)
            } catch {
                self?.errorMessage = String(localized: "RavanGo could not save this script. Your last saved version was restored.")
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

#Preview {
    NavigationStack {
        ScriptEditorView(script: Script(
            title: "Product Intro",
            content: "This is a realistic preview script with enough text to show the editor layout."
        ))
    }
    .environmentObject(PreferencesStore(defaults: UserDefaults(suiteName: "EditorPreview") ?? .standard))
    .modelContainer(for: Script.self, inMemory: true)
}
