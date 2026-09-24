import XCTest
@testable import RavanGo

@MainActor
final class PreferencesStoreTests: XCTestCase {
    func testPreferencesPersistAndReload() {
        let suiteName = "RavanGoTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create isolated UserDefaults")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = PreferencesStore(defaults: defaults)
        store.update { values in
            values.wordsPerMinute = 155
            values.defaultFontSize = 52
            values.language = .persian
        }

        let reloaded = PreferencesStore(defaults: defaults)
        XCTAssertEqual(reloaded.values.wordsPerMinute, 155)
        XCTAssertEqual(reloaded.values.defaultFontSize, 52)
        XCTAssertEqual(reloaded.values.language, .persian)
    }
}
