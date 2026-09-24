import OSLog
import SwiftData

enum ScriptStorageError: LocalizedError {
    case saveFailed

    var errorDescription: String? {
        String(localized: "RavanGo could not save your scripts. Please try again.")
    }
}

@MainActor
enum ScriptStorageService {
    private static let logger = Logger(subsystem: AppConstants.bundleIdentifier, category: "ScriptStorage")

    static func save(_ context: ModelContext) throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            logger.error("SwiftData save failed: \(String(describing: error), privacy: .public)")
            throw ScriptStorageError.saveFailed
        }
    }
}
