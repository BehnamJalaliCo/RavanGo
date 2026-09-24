import Foundation
import OSLog
import SwiftUI

@MainActor
final class PreferencesStore: ObservableObject {
    @Published private(set) var values: UserPreferences
    @Published private(set) var errorMessage: String? = nil

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let logger = Logger(subsystem: AppConstants.bundleIdentifier, category: "Preferences")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: AppConstants.preferencesKey),
           !data.isEmpty {
            do {
                values = try decoder.decode(UserPreferences.self, from: data)
            } catch {
                values = UserPreferences()
                errorMessage = String(localized: "RavanGo could not read its saved preferences. Default settings are active.")
                logger.error("Preference decoding failed: \(String(describing: error), privacy: .public)")
            }
        } else {
            values = UserPreferences()
        }
    }

    var colorScheme: ColorScheme? { values.appearance.colorScheme }

    func update(_ change: (inout UserPreferences) -> Void) {
        change(&values)
        save()
    }

    func save() {
        do {
            let data = try encoder.encode(values)
            defaults.set(data, forKey: AppConstants.preferencesKey)
            errorMessage = nil
        } catch {
            errorMessage = String(localized: "RavanGo could not save your preferences.", locale: values.language.locale)
            logger.error("Preference encoding failed: \(String(describing: error), privacy: .public)")
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func reset() {
        values = UserPreferences()
        save()
    }
}
