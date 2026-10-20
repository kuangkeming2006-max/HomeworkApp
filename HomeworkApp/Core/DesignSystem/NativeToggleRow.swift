import SwiftUI

/// Keep the native switch's hit and accessibility bounds on the control, not a wide form row.
struct NativeToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let identifier: String
    var body: some View {
        HStack {
            Text(title).accessibilityHidden(true)
            Spacer(minLength: 12)
            Toggle(title, isOn: $isOn).labelsHidden().fixedSize()
                .accessibilityIdentifier(identifier)
        }
    }
}
