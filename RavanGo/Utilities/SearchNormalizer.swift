import Foundation

enum SearchNormalizer {
    static func normalized(_ text: String) -> String {
        text
            .precomposedStringWithCanonicalMapping
            .replacingOccurrences(of: "ي", with: "ی")
            .replacingOccurrences(of: "ى", with: "ی")
            .replacingOccurrences(of: "ك", with: "ک")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "fa"))
            .lowercased()
    }
}
