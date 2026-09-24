import Foundation

enum ScriptMetrics {
    static func wordCount(in text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace }).count
    }

    static func estimatedDuration(for text: String, wordsPerMinute: Double) -> TimeInterval {
        guard wordsPerMinute > 0 else { return 0 }
        return Double(wordCount(in: text)) / wordsPerMinute * 60
    }

    static func formattedDuration(for text: String, wordsPerMinute: Double, language: AppLanguage = .english) -> String {
        let totalSeconds = Int(estimatedDuration(for: text, wordsPerMinute: wordsPerMinute).rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        let formattedMinutes = minutes.formatted(.number.locale(language.locale))
        let formattedSeconds = seconds.formatted(.number.locale(language.locale))
        if language == .persian {
            if minutes == 0 { return "\(formattedSeconds) ثانیه" }
            if seconds == 0 { return "\(formattedMinutes) دقیقه" }
            return "\(formattedMinutes) دقیقه و \(formattedSeconds) ثانیه"
        }
        if minutes == 0 { return "\(formattedSeconds)s" }
        if seconds == 0 { return "\(formattedMinutes)m" }
        return "\(formattedMinutes)m \(formattedSeconds)s"
    }
}

enum AppFormatting {
    static func integer(_ value: Double, locale: Locale) -> String {
        Int(value.rounded()).formatted(.number.locale(locale))
    }

    static func decimal(_ value: Double, locale: Locale, fractionDigits: Int = 2) -> String {
        value.formatted(.number.precision(.fractionLength(0...fractionDigits)).locale(locale))
    }

    static func speed(_ value: Double, language: AppLanguage) -> String {
        "\(decimal(value, locale: language.locale))x"
    }

    static func points(_ value: Double, language: AppLanguage) -> String {
        let number = integer(value, locale: language.locale)
        let unit = String(localized: "points_short", locale: language.locale)
        return "\(number) \(unit)"
    }

    static func percentage(_ value: Double, language: AppLanguage) -> String {
        let number = integer(value * 100, locale: language.locale)
        let unit = String(localized: "percent_sign", locale: language.locale)
        return "\(number)\(unit)"
    }

    static func wordsPerMinute(_ value: Double, language: AppLanguage) -> String {
        let number = integer(value, locale: language.locale)
        let unit = String(localized: "wpm_short", locale: language.locale)
        return "\(number) \(unit)"
    }
}
