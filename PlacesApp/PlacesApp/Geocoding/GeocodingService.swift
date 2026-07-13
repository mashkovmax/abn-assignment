import CoreLocation

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

/// `CLGeocoder`-backed forward geocoding using async/await.
struct CLGeocoderService: Geocoding {
    func geocode(_ query: String) async throws -> GeocodedPlace {
        // A fresh geocoder per request keeps each lookup independent.
        let placemarks = try await CLGeocoder().geocodeAddressString(query)
        guard let placemark = placemarks.first, let location = placemark.location else {
            throw GeocodingError.notFound
        }
        return GeocodedPlace(
            name: placemark.name ?? placemark.locality,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }
}
