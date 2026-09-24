import SwiftUI

struct SliderSettingRow<Value: BinaryFloatingPoint>: View where Value.Stride: BinaryFloatingPoint {
    let title: LocalizedStringKey
    let valueLabel: String
    @Binding var value: Value
    let range: ClosedRange<Value>
    let step: Value.Stride

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(valueLabel)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range, step: step)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(valueLabel)
    }
}
