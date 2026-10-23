import SwiftUI

struct ThemeColorPicker: View {
    @Bindable var preferences: AppPreferences

    var body: some View {
        List(AppAccent.allCases) { accent in
            Button {
                preferences.accent = accent
                AppHaptics.selection()
            } label: {
                HStack(spacing: 14) {
                    Circle().fill(accent.color).frame(width: 26, height: 26)
                        .overlay { Circle().stroke(.primary.opacity(0.12), lineWidth: 0.5) }
                    Text(accent.rawValue).foregroundStyle(.primary)
                    Spacer()
                    if preferences.accent == accent {
                        Image(systemName: "checkmark").fontWeight(.semibold).foregroundStyle(.primary)
                    }
                }.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.accent.\(accent.rawValue.lowercased())")
            .accessibilityAddTraits(preferences.accent == accent ? [.isSelected] : [])
        }
        .navigationTitle("Theme color").navigationBarTitleDisplayMode(.inline).tint(.blue)
    }
}
