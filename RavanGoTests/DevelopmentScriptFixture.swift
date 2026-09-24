import XCTest
@testable import RavanGo

enum DevelopmentScriptFixture {
    static let longScript: String = (1...5_000)
        .map { "development-word-\($0)" }
        .joined(separator: " ")
}

final class DevelopmentScriptFixtureTests: XCTestCase {
    func testLongDevelopmentScriptHasSeveralThousandWords() {
        XCTAssertEqual(ScriptMetrics.wordCount(in: DevelopmentScriptFixture.longScript), 5_000)
    }
}
