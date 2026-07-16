import Foundation
import Observation

/// Drives the locations list and the custom-location entry.
///
/// `@Observable` (Observation framework) + `@MainActor` so state changes are
/// tracked by SwiftUI and mutated on the main thread; loading runs through Swift
/// Concurrency (`async`/`await`) with a cancellable `Task`.
@MainActor
@Observable
final class LocationsViewModel {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded([Location])
        case failed(String)
    }

    private(set) var state: LoadState = .idle
    /// Locations the user added by hand (custom coordinate or geocoded city).
    /// Kept separate from the feed so a refresh doesn't wipe them.
    private(set) var customLocations: [Location] = []
    var alert: AlertMessage?

    private let service: LocationsServing
    private let opener: URLOpening

    init(service: LocationsServing = LocationsService(), opener: URLOpening = SystemURLOpener()) {
        self.service = service
        self.opener = opener
    }

    /// Fetches the locations feed, updating `state` as it goes. Runs as a
    /// structured child of the caller's task, so SwiftUI's `.task`/`.refreshable`
    /// cancellation propagates into the network call automatically.
    func loadLocations() async {
        state = .loading
        do {
            let locations = try await service.fetchLocations()
            try Task.checkCancellation()
            state = .loaded(locations)
        } catch is CancellationError {
            // View went away / superseded — leave state untouched.
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Opening Wikipedia

    /// Opens the Wikipedia app's Places tab centered on the given feed location.
    func open(_ location: Location) {
        guard let url = WikipediaDeepLink.placesURL(for: location) else {
            alert = .invalidLocation
            return
        }
        openWikipedia(url)
    }

    // MARK: - Custom locations

    /// Adds a (pre-validated) location to the top of the user's locations list.
    /// The user then taps it to open Wikipedia, like any other location.
    func addCustomLocation(_ location: Location) {
        // Move an existing duplicate to the top rather than adding it twice.
        customLocations.removeAll { $0.id == location.id }
        customLocations.insert(location, at: 0)
    }

    /// Removes user-added locations at the given list offsets (swipe-to-delete).
    func deleteCustomLocations(at offsets: IndexSet) {
        customLocations.remove(atOffsets: offsets)
    }

    private func openWikipedia(_ url: URL) {
        guard opener.canOpen(url) else {
            alert = .wikipediaNotInstalled
            return
        }
        Task { [opener] in
            await opener.open(url)
        }
    }
}

/// A validated latitude/longitude pair parsed from user text input.
struct CustomCoordinate: Equatable {
    let latitude: Double
    let longitude: Double

    init?(latitude: String, longitude: String) {
        let latString = latitude.trimmingCharacters(in: .whitespacesAndNewlines)
        let lonString = longitude.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let lat = Double(latString), let lon = Double(lonString) else { return nil }
        guard (-90...90).contains(lat), (-180...180).contains(lon) else { return nil }
        self.latitude = lat
        self.longitude = lon
    }
}

/// Lightweight, identifiable alert payload for SwiftUI `.alert(item:)`.
struct AlertMessage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String

    static let wikipediaNotInstalled = AlertMessage(
        title: "Wikipedia not installed",
        message: "Install the (modified) Wikipedia app to open this location in the Places tab."
    )
    static let invalidLocation = AlertMessage(
        title: "Could not open location",
        message: "The deep link could not be created for this location."
    )
}
