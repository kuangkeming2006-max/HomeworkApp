import SwiftUI

struct TimeZoneSelector: View {
    @Binding var selection: String
    @State private var search = ""
    @Environment(\.dismiss) private var dismiss
    private static let identifiers = TimeZone.knownTimeZoneIdentifiers.sorted()

    var body: some View {
        List {
            Button("Use system time zone") { selection = TimeZone.current.identifier; dismiss() }
            ForEach(Self.identifiers.filter { search.isEmpty || $0.localizedStandardContains(search) }, id: \.self) { identifier in
                Button {
                    selection = identifier; dismiss()
                } label: {
                    HStack {
                        Text(identifier).foregroundStyle(.primary)
                        Spacer()
                        if selection == identifier { Image(systemName: "checkmark").accessibilityHidden(true) }
                    }
                }.accessibilityAddTraits(selection == identifier ? .isSelected : [])
            }
        }
        .searchable(text: $search, prompt: "Search time zones")
        .navigationTitle("Time zone")
    }
}
