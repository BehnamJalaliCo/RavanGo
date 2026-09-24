import OSLog
import SwiftData
import SwiftUI

@main
@MainActor
struct RavanGoApp: App {
    @StateObject private var preferences = PreferencesStore()
    @StateObject private var persistence = PersistenceController()

    var body: some Scene {
        WindowGroup {
            PersistenceBootstrapView(controller: persistence)
                .environmentObject(preferences)
                .environment(\.locale, preferences.values.language.locale)
                .environment(\.layoutDirection, preferences.values.language.layoutDirection)
                .font(AppFont.uiFont(for: preferences.values.language))
                .preferredColorScheme(preferences.colorScheme)
        }
    }
}

@MainActor
private final class PersistenceController: ObservableObject {
    @Published private(set) var container: ModelContainer? = nil
    @Published private(set) var errorMessage: String? = nil

    private let logger = Logger(subsystem: AppConstants.bundleIdentifier, category: "Persistence")

    init() {
        loadContainer()
    }

    func retry() {
        loadContainer()
    }

    private func loadContainer() {
        do {
            container = try ModelContainer(for: Script.self)
            errorMessage = nil
        } catch {
            container = nil
            errorMessage = String(localized: "RavanGo could not open its local script library. Please try again.")
            logger.error("Persistent SwiftData initialization failed: \(String(describing: error), privacy: .public)")
        }
    }
}

@MainActor
private struct PersistenceBootstrapView: View {
    @ObservedObject var controller: PersistenceController

    var body: some View {
        Group {
            if let container = controller.container {
                ScriptsView()
                    .modelContainer(container)
            } else {
                PersistenceUnavailableView(
                    message: controller.errorMessage ?? String(localized: "RavanGo is preparing its local script library."),
                    retry: controller.retry
                )
            }
        }
    }
}

@MainActor
private struct PersistenceUnavailableView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Local Storage Unavailable", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
