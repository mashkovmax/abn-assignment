import Testing
import Foundation
@testable import PlacesApp

@Suite("Wikipedia deep link")
struct WikipediaDeepLinkTests {

    @Test func buildsSchemeAndHost() throws {
        let url = try #require(WikipediaDeepLink.placesURL(latitude: 52.3547498, longitude: 4.8339215))
        #expect(url.scheme == "wikipedia")
        #expect(url.host == "places")
    }

    @Test func includesLatAndLonQueryItems() throws {
        let url = try #require(WikipediaDeepLink.placesURL(latitude: 52.3547498, longitude: 4.8339215))
        let items = queryItems(url)
        #expect(items["lat"] == "52.3547498")
        #expect(items["lon"] == "4.8339215")
    }

    @Test func omitsTitleWhenNameIsNil() throws {
        let url = try #require(WikipediaDeepLink.placesURL(latitude: 1, longitude: 2, name: nil))
        #expect(queryItems(url)["title"] == nil)
    }

    @Test func omitsTitleWhenNameIsEmpty() throws {
        let url = try #require(WikipediaDeepLink.placesURL(latitude: 1, longitude: 2, name: ""))
        #expect(queryItems(url)["title"] == nil)
    }

    @Test func encodesTitleWithSpaces() throws {
        let url = try #require(WikipediaDeepLink.placesURL(latitude: 1, longitude: 2, name: "New York"))
        // URLComponents percent-encodes the space in the raw string...
        #expect(url.absoluteString.contains("title=New%20York"))
        // ...and it decodes back cleanly.
        #expect(queryItems(url)["title"] == "New York")
    }

    @Test func buildsFromLocation() throws {
        let location = Location(name: "Copenhagen", latitude: 55.6713442, longitude: 12.523785)
        let url = try #require(WikipediaDeepLink.placesURL(for: location))
        let items = queryItems(url)
        #expect(items["lat"] == "55.6713442")
        #expect(items["title"] == "Copenhagen")
    }

    @Test func usesDotDecimalSeparatorForNegativeCoordinate() throws {
        let url = try #require(WikipediaDeepLink.placesURL(latitude: 40.4380638, longitude: -3.7495758))
        #expect(queryItems(url)["lon"] == "-3.7495758")
    }

    // MARK: - Helper

    private func queryItems(_ url: URL) -> [String: String] {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var result: [String: String] = [:]
        for item in components?.queryItems ?? [] {
            result[item.name] = item.value
        }
        return result
    }
}
