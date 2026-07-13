import Foundation

/// Builds the `wikipedia://places?lat=..&lon=..` deep link understood by the
/// (modified) Wikipedia app. Opening this URL sends Wikipedia straight to its
/// Places tab, centered on the given coordinate instead of the user's location.
///
/// Kept as a pure, dependency-free helper so it is trivial to unit test.
enum WikipediaDeepLink {
    static let scheme = "wikipedia"
    static let host = "places"

    /// Builds the deep link for an explicit coordinate and optional place name.
    static func placesURL(latitude: Double, longitude: Double, name: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host

        var items = [
            URLQueryItem(name: "lat", value: format(latitude)),
            URLQueryItem(name: "lon", value: format(longitude))
        ]
        if let name, !name.isEmpty {
            items.append(URLQueryItem(name: "title", value: name))
        }
        components.queryItems = items
        return components.url
    }

    /// Convenience overload for a `Location` from the feed.
    static func placesURL(for location: Location) -> URL? {
        placesURL(latitude: location.latitude, longitude: location.longitude, name: location.name)
    }

    /// Formats a coordinate with a `.` decimal separator regardless of locale,
    /// so the query string is always parseable by the receiving app.
    private static func format(_ value: Double) -> String {
        String(value)
    }
}
