import MapKit

/// A place resolved from a free-text query (e.g. a city name).
struct GeocodedPlace: Equatable, Sendable {
    let name: String?
    let latitude: Double
    let longitude: Double
}

/// Abstraction over forward geocoding so the view model can be tested without
/// hitting Apple's geocoding service.
protocol Geocoding: Sendable {
    /// Resolves a place name / address into a coordinate.
    func geocode(_ query: String) async throws -> GeocodedPlace
}

enum GeocodingError: LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Couldn't find a place with that name."
        }
    }
}

/// MapKit-backed forward geocoding using async/await (`MKGeocodingRequest`, the
/// iOS 26 replacement for the deprecated `CLGeocoder`).
struct MapKitGeocoderService: Geocoding {
    func geocode(_ query: String) async throws -> GeocodedPlace {
        guard let request = MKGeocodingRequest(addressString: query) else {
            throw GeocodingError.notFound
        }
        let mapItems = try await request.mapItems
        guard let item = mapItems.first else {
            throw GeocodingError.notFound
        }
        let coordinate = item.location.coordinate
        return GeocodedPlace(
            name: item.name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}
