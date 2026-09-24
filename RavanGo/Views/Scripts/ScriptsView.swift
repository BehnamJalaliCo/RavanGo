import SwiftData
import SwiftUI

@MainActor
struct ScriptsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var preferences: PreferencesStore
    @Query(sort: [SortDescriptor(\Script.updatedAt, order: .reverse)]) private var scripts: [Script]

    @State private var searchText = ""
    @State private var editingScript: Script?
    @State private var showingSettings = false
    @State private var showingStorageError = false
    @State private var errorMessage = ""
    @AppStorage(AppConstants.didSeedWelcomeKey) private var didSeedWelcome = false

    private var filteredScripts: [Script] {
        guard !searchText.isEmpty else { return scripts }
        let normalizedQuery = SearchNormalizer.normalized(searchText)
        return scripts.filter {
            SearchNormalizer.normalized($0.title).contains(normalizedQuery) ||
            SearchNormalizer.normalized($0.content).contains(normalizedQuery)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if scripts.isEmpty {
                    EmptyStateView(
                        title: "No Scripts Yet",
                        message: "Create a script, then open Teleprompter when you are ready to read.",
                        actionTitle: "Create Script",
                        action: createScript
                    )
                } else {
                    List {
                        ForEach(filteredScripts) { script in
                            Button {
                                editingScript = script
                            } label: {
                                ScriptRowView(script: script)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(script)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    duplicate(script)
                                } label: {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                Button {
                                    rename(script)
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                Button {
                                    duplicate(script)
                                } label: {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }
                                Button(role: .destructive) {
                                    delete(script)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Scripts")
            .searchable(text: $searchText, prompt: "Search scripts")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: createScript) {
                        Label("Create Script", systemImage: "square.and.pencil")
                    }
                }
            }
            .sheet(item: $editingScript) { script in
                NavigationStack {
                    ScriptEditorView(script: script)
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView()
                }
            }
            .alert("Storage Error", isPresented: $showingStorageError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                seedSampleIfNeeded()
            }
        }
    }

    private func createScript() {
        let script = Script()
        modelContext.insert(script)
        if saveContext() {
            editingScript = script
        }
    }

    private func duplicate(_ script: Script) {
        let copy = Script(title: uniqueTitle(for: script.title), content: script.content)
        modelContext.insert(copy)
        if saveContext() {
            editingScript = copy
        }
    }

    private func rename(_ script: Script) {
        // The editor provides the full title field. Opening it is safer than
        // using a small inline alert text field on iPhone.
        editingScript = script
    }

    private func delete(_ script: Script) {
        modelContext.delete(script)
        do {
            try ScriptStorageService.save(modelContext)
        } catch {
            errorMessage = String(localized: "The script could not be removed. Please try again.")
            showingStorageError = true
        }
    }

    private func uniqueTitle(for original: String) -> String {
        let base = original.isEmpty ? "Untitled Script" : original
        let titles = Set(scripts.map { $0.title.lowercased() })
        var candidate = "\(base) Copy"
        var index = 2
        while titles.contains(candidate.lowercased()) {
            candidate = "\(base) Copy \(index)"
            index += 1
        }
        return candidate
    }

    @discardableResult
    private func saveContext() -> Bool {
        do {
            try ScriptStorageService.save(modelContext)
            return true
        } catch {
            errorMessage = String(localized: "RavanGo could not save this script. Please try again.")
            showingStorageError = true
            return false
        }
    }

    private func seedSampleIfNeeded() {
        guard scripts.isEmpty, !didSeedWelcome else { return }
        let sample = Script(
            title: String(localized: "sample_welcome_title", locale: preferences.values.language.locale),
            content: String(localized: "sample_welcome_content", locale: preferences.values.language.locale)
        )
        modelContext.insert(sample)
        if saveContext() {
            didSeedWelcome = true
        }
    }
}

#Preview {
    ScriptsView()
        .environmentObject(PreferencesStore(defaults: UserDefaults(suiteName: "ScriptsPreview") ?? .standard))
        .modelContainer(for: Script.self, inMemory: true)
}
