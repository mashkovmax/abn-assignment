import Testing
import Foundation
@testable import PlacesApp

/// Exercises the real `LocationsService` against a stubbed `URLSession`
/// (no network). Serialized because the stub uses shared static state.
@Suite("Locations service", .serialized)
struct LocationsServiceTests {

    private let validFeed = """
    {
      "locations": [
        { "name": "Amsterdam", "lat": 52.3547498, "long": 4.8339215 },
        { "lat": 40.4380638, "long": -3.7495758 }
      ]
    }
    """

    @Test func fetchDecodesValidFeed() async throws {
        let service = makeService(body: validFeed, status: 200)
        let locations = try await service.fetchLocations()
        #expect(locations.count == 2)
        #expect(locations.first?.name == "Amsterdam")
        #expect(locations.last?.name == nil)
    }

    @Test func fetchThrowsBadStatusOnServerError() async {
        let service = makeService(body: validFeed, status: 500)
        await #expect(throws: LocationsServiceError.badStatus(500)) {
            try await service.fetchLocations()
        }
    }

    @Test func fetchThrowsOnMalformedJSON() async {
        let service = makeService(body: "{ not json", status: 200)
        await #expect(throws: (any Error).self) {
            try await service.fetchLocations()
        }
    }

    @Test func fetchPropagatesTransportError() async {
        StubURLProtocol.responder = { _ in throw SampleError.boom }
        await #expect(throws: (any Error).self) {
            try await makeServiceWithStubSession().fetchLocations()
        }
    }

    @Test func badStatusErrorDescriptionIncludesCode() {
        #expect(LocationsServiceError.badStatus(404).errorDescription?.contains("404") == true)
    }

    // MARK: - Helpers

    private func makeService(body: String, status: Int) -> LocationsService {
        let data = Data(body.utf8)
        StubURLProtocol.responder = { _ in (data, status) }
        return makeServiceWithStubSession()
    }

    private func makeServiceWithStubSession() -> LocationsService {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: config)
        return LocationsService(url: URL(string: "https://example.com/locations.json")!, session: session)
    }
}

private enum SampleError: Error { case boom }

/// A `URLProtocol` that returns canned responses for `LocationsService` tests.
final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responder: (@Sendable (URLRequest) throws -> (Data, Int))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let responder = Self.responder else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        do {
            let (data, status) = try responder(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
