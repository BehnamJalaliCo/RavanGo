import Foundation
import SwiftData
import XCTest
@testable import RavanGo

final class ImportExportServiceTests: XCTestCase {
    func testScriptsRoundTripThroughJSON() throws {
        let transfer = ScriptTransfer(
            id: UUID(),
            title: "Demo",
            content: "Hello from a backup.",
            createdAt: Date(timeIntervalSince1970: 100),
            updatedAt: Date(timeIntervalSince1970: 200)
        )

        let data = try ImportExportService.encode([transfer])
        let decoded = try ImportExportService.decode(data)

        XCTAssertEqual(decoded, [transfer])
    }

    func testPersianAndMixedUnicodeRoundTripWithoutMutation() throws {
        let content = "سلام دنیا ۱۲۳ — Hello RavanGo 🌿"
        let transfer = ScriptTransfer(
            id: UUID(), title: "خوش آمدید", content: content,
            createdAt: Date(timeIntervalSince1970: 100), updatedAt: Date(timeIntervalSince1970: 200),
            direction: .rightToLeft
        )

        let decoded = try ImportExportService.decode(try ImportExportService.encode([transfer]))
        XCTAssertEqual(decoded.first?.content, content)
        XCTAssertEqual(decoded.first?.title, "خوش آمدید")
        XCTAssertEqual(decoded.first?.directionRawValue, ScriptDirection.rightToLeft.rawValue)
    }

    func testMalformedJSONThrowsUserFacingError() {
        XCTAssertThrowsError(try ImportExportService.decode(Data("not json".utf8))) { error in
            XCTAssertEqual(error as? ImportExportError, .invalidFile)
        }
    }

    func testEmptyBackupThrowsUsefulError() {
        XCTAssertThrowsError(try ImportExportService.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? ImportExportError, .emptyFile)
        }
    }

    @MainActor
    func testImportCreatesSafeDuplicateTitle() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Script.self, configurations: configuration)
        let context = ModelContext(container)
        let existing = Script(title: "Demo", content: "Existing")
        context.insert(existing)
        try context.save()

        let transfer = ScriptTransfer(
            id: UUID(), title: "Demo", content: "Imported",
            createdAt: .now, updatedAt: .now
        )
        let data = try ImportExportService.encode([transfer])
        XCTAssertEqual(try ImportExportService.importScripts(from: data, into: context, existingScripts: [existing]), 1)

        let allScripts = try context.fetch(FetchDescriptor<Script>())
        guard let imported = allScripts.first(where: { $0.title == "Demo (Imported)" }) else {
            XCTFail("The imported duplicate was not created")
            return
        }
        XCTAssertNotEqual(imported.id, transfer.id)
    }
}
