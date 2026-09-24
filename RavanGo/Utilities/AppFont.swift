import CoreText
import SwiftUI
import UIKit

@MainActor
enum AppFont {
    static let regular = "IRANYekanXFaNum-Regular"
    static let medium = "IRANYekanXFaNum-Medium"
    static let demiBold = "IRANYekanXFaNum-DemiBold"
    static let bold = "IRANYekanXFaNum-Bold"

    private static let bundledFiles = [
        "IRANYekanXFaNum-Regular",
        "IRANYekanXFaNum-Medium",
        "IRANYekanXFaNum-DemiBold",
        "IRANYekanXFaNum-Bold"
    ]

    private static var didAttemptRegistration = false

    static func uiFont(
        for language: AppLanguage,
        style: Font.TextStyle = .body,
        weight: Font.Weight = .regular
    ) -> Font {
        guard language == .persian, isAvailable else {
            return .system(style, design: .default).weight(weight)
        }
        return .custom(fontName(for: weight), size: baseSize(for: style), relativeTo: style)
    }

    static func teleprompterFont(
        _ font: TeleprompterFont,
        size: CGFloat,
        direction: LayoutDirection
    ) -> Font {
        switch font {
        case .automatic:
            return direction == .rightToLeft && isAvailable
                ? .custom(regular, size: size)
                : .system(size: size)
        case .iranYekan:
            return isAvailable ? .custom(regular, size: size) : .system(size: size)
        case .system:
            return .system(size: size)
        case .rounded:
            return .system(size: size, design: .rounded)
        case .monospaced:
            return .system(size: size, design: .monospaced)
        }
    }

    static func registerBundledFontsIfPresent() {
        guard !didAttemptRegistration else { return }
        didAttemptRegistration = true

        for resource in bundledFiles {
            guard let url = Bundle.main.url(forResource: resource, withExtension: "ttf", subdirectory: "Fonts")
                ?? Bundle.main.url(forResource: resource, withExtension: "ttf") else {
                continue
            }

            var error: Unmanaged<CFError>?
            let registered = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)

            if !registered {
                let nsError = error?.takeRetainedValue() as Error?
                if let nsError {
                    NSLog("RavanGo could not register font %@: %@", resource, String(describing: nsError))
                }
            }
        }
    }

    private static var isAvailable: Bool {
        registerBundledFontsIfPresent()
        return UIFont(name: regular, size: 17) != nil
    }

    private static func fontName(for weight: Font.Weight) -> String {
        if weight == .bold || weight == .heavy || weight == .black { return bold }
        if weight == .semibold { return demiBold }
        if weight == .medium { return medium }
        return regular
    }

    private static func baseSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        case .subheadline: 15
        case .callout: 16
        case .caption: 12
        case .caption2: 11
        case .footnote: 13
        default: 17
        }
    }
}
