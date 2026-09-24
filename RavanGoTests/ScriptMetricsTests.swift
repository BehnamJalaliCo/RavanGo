import XCTest
@testable import RavanGo

final class ScriptMetricsTests: XCTestCase {
    func testWordCountIgnoresRepeatedWhitespace() {
        XCTAssertEqual(ScriptMetrics.wordCount(in: "One  two\nthree"), 3)
    }

    func testEstimatedDurationUsesWordsPerMinute() {
        XCTAssertEqual(ScriptMetrics.estimatedDuration(for: "one two three four", wordsPerMinute: 120), 2, accuracy: 0.001)
    }

    func testFormattedDurationIncludesMinutesAndSeconds() {
        XCTAssertEqual(ScriptMetrics.formattedDuration(for: String(repeating: "word ", count: 195), wordsPerMinute: 130), "1m 30s")
    }

    func testPersianDominantTextResolvesRightToLeft() {
        XCTAssertEqual(ScriptDirection.automatic.resolvedLayoutDirection(for: "سلام دنیا"), .rightToLeft)
    }

    func testEnglishDominantTextResolvesLeftToRight() {
        XCTAssertEqual(ScriptDirection.automatic.resolvedLayoutDirection(for: "Hello world"), .leftToRight)
    }

    func testEmptyTextUsesLeftToRightDefault() {
        XCTAssertEqual(ScriptDirection.automatic.resolvedLayoutDirection(for: ""), .leftToRight)
    }

    func testSearchNormalizationHandlesArabicVariants() {
        XCTAssertEqual(SearchNormalizer.normalized("ي ك"), SearchNormalizer.normalized("ی ک"))
        XCTAssertEqual(SearchNormalizer.normalized("كی"), SearchNormalizer.normalized("کی"))
    }
}
