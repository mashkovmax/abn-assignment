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

    /// Validates free-form custom input and, if valid, opens Wikipedia there.
    /// Returns `true` when the input was valid and an open was attempted.
    @discardableResult
    func openCustomLocation(name: String, latitude: String, longitude: String) -> Bool {
        guard let coordinate = CustomCoordinate(latitude: latitude, longitude: longitude) else {
            alert = .invalidCoordinates
            return false
        }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = WikipediaDeepLink.placesURL(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            name: trimmedName.isEmpty ? nil : trimmedName
        ) else {
            alert = .invalidLocation
            return false
        }
        openWikipedia(url)
        return true
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
    static let invalidCoordinates = AlertMessage(
        title: "Invalid coordinates",
        message: "Enter a latitude between -90 and 90 and a longitude between -180 and 180."
    )
    static let invalidLocation = AlertMessage(
        title: "Could not open location",
        message: "The deep link could not be created for this location."
    )
}
