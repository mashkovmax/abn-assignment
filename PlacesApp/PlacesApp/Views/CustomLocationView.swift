import SwiftUI

/// A sheet letting the user type an arbitrary coordinate (and optional name)
/// and open it in Wikipedia's Places tab.
///
/// The parent supplies `onOpen`, which validates + attempts the open and
/// returns whether it succeeded; the sheet stays up on invalid input so the
/// alert (owned by the parent) can be shown.
struct CustomLocationView: View {
    /// `(name, latitude, longitude) -> openedSuccessfully`
    let onOpen: (String, String, String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var latitude = ""
    @State private var longitude = ""

    private var hasCoordinates: Bool {
        !latitude.trimmingCharacters(in: .whitespaces).isEmpty &&
        !longitude.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    TextField("Name (optional)", text: $name)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel("Location name, optional")

                    TextField("Latitude (-90 to 90)", text: $latitude)
                        .keyboardType(.numbersAndPunctuation)
                        .accessibilityLabel("Latitude")

                    TextField("Longitude (-180 to 180)", text: $longitude)
                        .keyboardType(.numbersAndPunctuation)
                        .accessibilityLabel("Longitude")
                }

                Section {
                    Button {
                        _ = onOpen(name, latitude, longitude)
                    } label: {
                        Text("Open in Wikipedia")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasCoordinates)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } footer: {
                    Text("Example: Amsterdam is 52.3547, 4.8339.")
                }
            }
            .navigationTitle("Custom location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    CustomLocationView { _, _, _ in true }
}
