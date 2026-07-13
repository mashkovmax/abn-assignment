import SwiftUI

/// A sheet letting the user add an arbitrary coordinate to the locations list.
/// The coordinate can be typed directly, or looked up from a city / place name
/// via MapKit geocoding. Once added, the user taps it in the list to open it in
/// Wikipedia's Places tab.
///
/// The parent supplies `onAdd`, called with an already-validated `Location`.
/// Validation and dismissal are handled here in the sheet.
struct CustomLocationView: View {
    let onAdd: (Location) -> Void

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
                        if let location = viewModel.validatedLocation() {
                            onAdd(location)
                            dismiss()
                        }
                    } label: {
                        Text("Add to list")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasCoordinates)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } footer: {
                    if let validationMessage = viewModel.validationMessage {
                        Text(validationMessage).foregroundStyle(.red)
                    } else {
                        Text("Example: Amsterdam is 52.3547, 4.8339. It's added to the list — tap it there to open Wikipedia.")
                    }
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
    CustomLocationView { _ in } // onAdd
}
