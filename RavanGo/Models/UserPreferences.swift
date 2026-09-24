import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Codable, Identifiable, Equatable, Sendable {
    case english = "en"
    case persian = "fa"

    var id: String { rawValue }
    var locale: Locale { Locale(identifier: rawValue) }
    var layoutDirection: LayoutDirection { self == .persian ? .rightToLeft : .leftToRight }
    var label: LocalizedStringKey { self == .persian ? "Persian" : "English" }
}

enum AppAppearance: String, CaseIterable, Codable, Identifiable, Equatable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .system: "Follow System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum CountdownDuration: Int, CaseIterable, Codable, Identifiable, Equatable {
    case off = 0
    case three = 3
    case five = 5
    case ten = 10

    var id: Int { rawValue }
    var label: LocalizedStringKey {
        switch self {
        case .off: "Off"
        case .three: "3 seconds"
        case .five: "5 seconds"
        case .ten: "10 seconds"
        }
    }
}

enum TeleprompterFont: String, CaseIterable, Codable, Identifiable, Equatable {
    case automatic
    case system
    case rounded
    case monospaced
    case iranYekan

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .automatic: "Automatic"
        case .system: "System"
        case .rounded: "Rounded"
        case .monospaced: "Monospaced"
        case .iranYekan: "IRANYekanX"
        }
    }

    var design: Font.Design {
        switch self {
        case .automatic, .iranYekan, .system: .default
        case .rounded: .rounded
        case .monospaced: .monospaced
        }
    }
}

enum TextAlignmentOption: String, CaseIterable, Codable, Identifiable, Equatable {
    case leading
    case center

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .leading: "Left"
        case .center: "Center"
        }
    }

    var alignment: TextAlignment {
        switch self {
        case .leading: .leading
        case .center: .center
        }
    }
}

enum TextColorOption: String, CaseIterable, Codable, Identifiable, Equatable {
    case white
    case warmWhite
    case yellow

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .white: "White"
        case .warmWhite: "Warm White"
        case .yellow: "Yellow"
        }
    }

    var color: Color {
        switch self {
        case .white: .white
        case .warmWhite: Color(red: 1.0, green: 0.97, blue: 0.88)
        case .yellow: .yellow
        }
    }
}

enum BackgroundColorOption: String, CaseIterable, Codable, Identifiable, Equatable {
    case black
    case charcoal
    case navy

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .black: "Black"
        case .charcoal: "Charcoal"
        case .navy: "Navy"
        }
    }

    var color: Color {
        switch self {
        case .black: .black
        case .charcoal: Color(red: 0.055, green: 0.06, blue: 0.075)
        case .navy: Color(red: 0.02, green: 0.04, blue: 0.09)
        }
    }
}

struct UserPreferences: Codable, Equatable, Sendable {
    var language: AppLanguage = .english
    var defaultSpeed = 1.0
    var defaultFontSize = 44.0
    var defaultLineSpacing = 12.0
    var defaultMargins = 28.0
    var countdownDuration: CountdownDuration = .three
    var mirrorMode = false
    var focusGuide = false
    var focusGuidePosition = 0.5
    var wordsPerMinute = 130.0
    var appearance: AppAppearance = .system
    var font: TeleprompterFont = .automatic
    var textAlignment: TextAlignmentOption = .leading
    var textColor: TextColorOption = .white
    var backgroundColor: BackgroundColorOption = .black
}
