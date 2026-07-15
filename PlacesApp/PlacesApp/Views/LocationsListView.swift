import SwiftUI

/// The main screen: a list of locations fetched from the feed, plus an entry
/// point for opening a custom coordinate. Tapping a row opens the (modified)
/// Wikipedia app on its Places tab, centered on that location.
struct LocationsListView: View {
    @State private var viewModel = LocationsViewModel()
    @State private var isPresentingCustomLocation = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Places")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isPresentingCustomLocation = true
                        } label: {
                            Label("Add custom location", systemImage: "plus")
                        }
                        .accessibilityLabel("Add custom location")
                    }
                }
                .sheet(isPresented: $isPresentingCustomLocation) {
                    CustomLocationView { location in
                        viewModel.addCustomLocation(location)
                    }
                }
                .alert(item: $viewModel.alert) { alert in
                    Alert(
                        title: Text(alert.title),
                        message: Text(alert.message),
                        dismissButton: .default(Text("OK"))
                    )
                }
        }
        .task {
            if case .idle = viewModel.state {
                await viewModel.loadLocations()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading locations…")
                .accessibilityLabel("Loading locations")
        case .loaded(let locations):
            loadedList(locations)
        case .failed(let message):
            errorView(message)
        }
    }

    private func loadedList(_ locations: [Location]) -> some View {
        List {
            if !viewModel.customLocations.isEmpty {
                Section("Your locations") {
                    locationRows(viewModel.customLocations)
                }
            }

            if locations.isEmpty {
                Section {
                    Text("No locations available.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    locationRows(locations)
                } header: {
                    Text("From the feed")
                } footer: {
                    Text("Tap a location to open it in Wikipedia's Places tab.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadLocations()
        }
    }

    @ViewBuilder
    private func locationRows(_ locations: [Location]) -> some View {
        ForEach(locations) { location in
            Button {
                viewModel.open(location)
            } label: {
                LocationRow(location: location)
            }
            .buttonStyle(.plain)
        }
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn't load locations", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Retry") {
                Task { await viewModel.loadLocations() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

/// A single location row. Combined into one accessibility element so VoiceOver
/// reads the name and coordinates together, with a hint describing the action.
struct LocationRow: View {
    let location: Location

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .foregroundStyle(.tint)
                .font(.title2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(location.displayName)
                    .font(.headline)
                if location.name?.isEmpty == false {
                    Text(location.coordinateText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(location.displayName)
        .accessibilityHint("Opens this location in Wikipedia Places")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("Light") {
    LocationsListView()
}

#Preview("Dark") {
    LocationsListView()
        .preferredColorScheme(.dark)
}
