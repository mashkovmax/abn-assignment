import Foundation

/// Abstraction over the locations feed so the view model can be unit tested
/// with a mock instead of hitting the network.
protocol LocationsServing: Sendable {
    func fetchLocations() async throws -> [Location]
}

enum LocationsServiceError: LocalizedError {
    case invalidResponse
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .badStatus(let code):
            return "The server returned status code \(code)."
        }
    }
}

/// Fetches and decodes `locations.json` using async/await.
struct LocationsService: LocationsServing {
    /// The assignment brief points at `assignmentios`, but the live file is served
    /// from the `assignment-ios` repo — that is the URL used here.
    static let defaultURL = URL(string: "https://raw.githubusercontent.com/abnamrocoesd/assignment-ios/main/locations.json")!

    private let url: URL
    private let session: URLSession

    init(url: URL = LocationsService.defaultURL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    func fetchLocations() async throws -> [Location] {
        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw LocationsServiceError.invalidResponse
        }
        guard 200..<300 ~= http.statusCode else {
            throw LocationsServiceError.badStatus(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(LocationsResponse.self, from: data)
        return decoded.locations
    }
}
