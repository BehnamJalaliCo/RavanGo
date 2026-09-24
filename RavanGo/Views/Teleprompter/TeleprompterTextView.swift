import SwiftUI

struct TeleprompterTextView: View {
    let text: String
    let fontSize: Double
    let lineSpacing: Double
    let margins: Double
    let font: TeleprompterFont
    let alignment: TextAlignmentOption
    let textColor: TextColorOption
    let mirrored: Bool
    let viewportHeight: CGFloat
    let layoutDirection: LayoutDirection

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: max(24, viewportHeight * 0.42))

            Text(text)
                .font(AppFont.teleprompterFont(font, size: fontSize, text: text))
                .foregroundStyle(textColor.color)
                .multilineTextAlignment(alignment.alignment)
                .lineSpacing(lineSpacing)
                .frame(maxWidth: .infinity, alignment: alignment.frameAlignment)
                .scaleEffect(x: mirrored ? -1 : 1, y: 1)
                .padding(.horizontal, margins)

            Color.clear
                .frame(height: max(24, viewportHeight * 0.58))
        }
        .frame(maxWidth: .infinity)
        .environment(\.layoutDirection, layoutDirection)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Teleprompter script")
    }
}
