import Foundation
import Observation

/// Backs `CustomLocationView`: owns the editable fields and the "look up a city
/// name" geocoding flow. `@Observable` + `@MainActor` for SwiftUI binding and
/// safe state mutation.
@MainActor
@Observable
final class CustomLocationViewModel {

    enum GeocodeState: Equatable {
        case idle
        case searching
        case failed(String)
    }

    var name = ""
    var latitude = ""
    var longitude = ""
    private(set) var geocodeState: GeocodeState = .idle
    private(set) var validationMessage: String?

    private let geocoder: Geocoding

    init(geocoder: Geocoding = MapKitGeocoderService()) {
        self.geocoder = geocoder
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canLookUp: Bool { !trimmedName.isEmpty }
    var isSearching: Bool { geocodeState == .searching }

    /// Validates the entered coordinates and returns a `Location` to add, or
    /// `nil` (setting `validationMessage`) if the input is invalid.
    func validatedLocation() -> Location? {
        guard let coordinate = CustomCoordinate(latitude: latitude, longitude: longitude) else {
            validationMessage = "Enter a latitude between -90 and 90 and a longitude between -180 and 180."
            return nil
        }
        validationMessage = nil
        return Location(
            name: trimmedName.isEmpty ? nil : trimmedName,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    /// Geocodes the entered name and fills in the latitude/longitude fields.
    func lookUpCoordinates() async {
        let query = trimmedName
        guard !query.isEmpty else { return }

        geocodeState = .searching
        do {
            let place = try await geocoder.geocode(query)
            latitude = String(place.latitude)
            longitude = String(place.longitude)
            geocodeState = .idle
        } catch is CancellationError {
            geocodeState = .idle
        } catch {
            geocodeState = .failed(error.localizedDescription)
        }
    }
}
