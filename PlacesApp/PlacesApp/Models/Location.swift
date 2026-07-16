import Foundation

/// A place that can be opened in the Wikipedia app's "Places" tab.
///
/// The remote feed (`locations.json`) does not always include a `name` — some
/// entries only carry coordinates — so `name` is intentionally optional.
struct Location: Identifiable, Equatable, Codable, Sendable {
    let name: String?
    let latitude: Double
    let longitude: Double

    /// Stable identity derived from the coordinate + name so `List`/`ForEach`
    /// stay stable even though the feed has no explicit id.
    var id: String { "\(latitude),\(longitude),\(name ?? "")" }

    /// Human-readable title, falling back to the coordinates when the feed
    /// entry has no name.
    var displayName: String {
        if let name, !name.isEmpty { return name }
        return coordinateText
    }

    /// A short, formatted coordinate string, e.g. "52.3547, 4.8339".
    var coordinateText: String {
        String(format: "%.4f, %.4f", latitude, longitude)
    }

    enum CodingKeys: String, CodingKey {
        case name
        case latitude = "lat"
        case longitude = "long"
    }
}


