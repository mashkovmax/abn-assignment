import SwiftUI

/// A sheet letting the user open an arbitrary coordinate in Wikipedia's Places
/// tab. The coordinate can be typed directly, or looked up from a city / place
/// name via `CLGeocoder`.
///
/// The parent supplies `onOpen`, which validates + attempts the open and returns
/// whether it succeeded; the sheet stays up on invalid input so the alert (owned
/// by the parent) can be shown.
struct CustomLocationView: View {
    /// `(name, latitude, longitude) -> openedSuccessfully`
    let onOpen: (String, String, String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CustomLocationViewModel()

    private var hasCoordinates: Bool {
        !viewModel.latitude.trimmingCharacters(in: .whitespaces).isEmpty &&
        !viewModel.longitude.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section {
                    TextField("Name or city", text: $viewModel.name)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel("Location name or city")

                    Button {
                        Task { await viewModel.lookUpCoordinates() }
                    } label: {
                        HStack {
                            Label("Find coordinates from name", systemImage: "mappin.and.ellipse")
                            Spacer()
                            if viewModel.isSearching {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(!viewModel.canLookUp || viewModel.isSearching)
                    .accessibilityHint("Looks up the coordinates for the entered name")
                } header: {
                    Text("Location")
                } footer: {
                    if case .failed(let message) = viewModel.geocodeState {
                        Text(message).foregroundStyle(.red)
                    } else {
                        Text("Type a city name and tap “Find coordinates”, or enter coordinates directly below.")
                    }
                }

                Section("Coordinates") {
                    TextField("Latitude (-90 to 90)", text: $viewModel.latitude)
                        .keyboardType(.numbersAndPunctuation)
                        .accessibilityLabel("Latitude")

                    TextField("Longitude (-180 to 180)", text: $viewModel.longitude)
                        .keyboardType(.numbersAndPunctuation)
                        .accessibilityLabel("Longitude")
                }

                Section {
                    Button {
                        _ = onOpen(viewModel.name, viewModel.latitude, viewModel.longitude)
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
