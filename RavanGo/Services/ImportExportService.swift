import Foundation
import SwiftData

enum ImportExportError: LocalizedError, Equatable {
    case invalidFile
    case emptyFile
    case cannotWriteFile
    case storageFailure

    var errorDescription: String? {
        switch self {
        case .invalidFile: String(localized: "This file is not a valid RavanGo backup.")
        case .emptyFile: String(localized: "The backup does not contain any scripts.")
        case .cannotWriteFile: String(localized: "RavanGo could not create the export file.")
        case .storageFailure: String(localized: "RavanGo could not save the imported scripts.")
        }
    }

    func localizedMessage(for language: AppLanguage) -> String {
        switch self {
        case .invalidFile: String(localized: "This file is not a valid RavanGo backup.", locale: language.locale)
        case .emptyFile: String(localized: "The backup does not contain any scripts.", locale: language.locale)
        case .cannotWriteFile: String(localized: "RavanGo could not create the export file.", locale: language.locale)
        case .storageFailure: String(localized: "RavanGo could not save the imported scripts.", locale: language.locale)
        }
    }
}

enum ImportExportService {
    static func encode(_ transfers: [ScriptTransfer]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(transfers)
    }

    static func decode(_ data: Data) throws -> [ScriptTransfer] {
        guard !data.isEmpty else { throw ImportExportError.emptyFile }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let transfers = try decoder.decode([ScriptTransfer].self, from: data)
            guard !transfers.isEmpty else { throw ImportExportError.emptyFile }
            return transfers
        } catch let error as ImportExportError {
            throw error
        } catch {
            throw ImportExportError.invalidFile
        }
    }

    static func exportURL(for scripts: [Script]) throws -> URL {
        let data = try encode(scripts.map { ScriptTransfer(script: $0) })
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(AppConstants.exportFileName)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            throw ImportExportError.cannotWriteFile
        }
    }

    @MainActor
    static func importScripts(
        from data: Data,
        into context: ModelContext,
        existingScripts: [Script],
        language: AppLanguage = .english
    ) throws -> Int {
        let transfers = try decode(data)
        var existingTitles = Set(existingScripts.map { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        var insertedScripts: [Script] = []

        for transfer in transfers {
            let baseTitle = transfer.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? String(localized: "Imported Script", locale: language.locale)
                : transfer.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = uniqueImportedTitle(baseTitle, existingTitles: &existingTitles)
            let script = Script(
                title: title,
                content: transfer.content,
                createdAt: transfer.createdAt,
                updatedAt: .now,
                direction: ScriptDirection(rawValue: transfer.directionRawValue) ?? .automatic
            )
            context.insert(script)
            insertedScripts.append(script)
        }

        do {
            try ScriptStorageService.save(context)
        } catch {
            for script in insertedScripts {
                context.delete(script)
            }
            throw ImportExportError.storageFailure
        }
        return transfers.count
    }

    private static func uniqueImportedTitle(_ baseTitle: String, existingTitles: inout Set<String>) -> String {
        var candidate = baseTitle
        var suffix = 1
        while existingTitles.contains(candidate.lowercased()) {
            suffix += 1
            candidate = suffix == 2 ? "\(baseTitle) (Imported)" : "\(baseTitle) (Imported \(suffix - 1))"
        }
        existingTitles.insert(candidate.lowercased())
        return candidate
    }
}
