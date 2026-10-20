import SwiftUI

/// Keep the native switch's hit and accessibility bounds on the control, not a wide form row.
struct NativeToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let identifier: String
    @Environment(\.isEnabled) private var isEnabled
    var body: some View {
        HStack {
            // Form may expose the full row as the switch's accessibility frame.
            // The label is an intentional second hit target, separate from the switch,
            // so tapping either side toggles once without a parent/child gesture conflict.
            Text(title).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle()).onTapGesture { if isEnabled { isOn.toggle() } }.accessibilityHidden(true)
            Toggle(title, isOn: $isOn).labelsHidden().fixedSize()
                .accessibilityIdentifier(identifier)
        }
    }
}
