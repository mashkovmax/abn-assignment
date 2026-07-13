import XCTest
@testable import PlacesApp

final class WikipediaDeepLinkTests: XCTestCase {

    func testBuildsSchemeAndHost() throws {
        let url = try XCTUnwrap(WikipediaDeepLink.placesURL(latitude: 52.3547498, longitude: 4.8339215))
        XCTAssertEqual(url.scheme, "wikipedia")
        XCTAssertEqual(url.host, "places")
    }

    func testIncludesLatAndLonQueryItems() throws {
        let url = try XCTUnwrap(WikipediaDeepLink.placesURL(latitude: 52.3547498, longitude: 4.8339215))
        let items = queryItems(url)
        XCTAssertEqual(items["lat"], "52.3547498")
        XCTAssertEqual(items["lon"], "4.8339215")
    }

    func testOmitsTitleWhenNameIsNil() throws {
        let url = try XCTUnwrap(WikipediaDeepLink.placesURL(latitude: 1, longitude: 2, name: nil))
        XCTAssertNil(queryItems(url)["title"])
    }

    func testOmitsTitleWhenNameIsEmpty() throws {
        let url = try XCTUnwrap(WikipediaDeepLink.placesURL(latitude: 1, longitude: 2, name: ""))
        XCTAssertNil(queryItems(url)["title"])
    }

    func testEncodesTitleWithSpaces() throws {
        let url = try XCTUnwrap(WikipediaDeepLink.placesURL(latitude: 1, longitude: 2, name: "New York"))
        // URLComponents percent-encodes the space in the raw string...
        XCTAssertTrue(url.absoluteString.contains("title=New%20York"))
        // ...and it decodes back cleanly.
        XCTAssertEqual(queryItems(url)["title"], "New York")
    }

    func testBuildsFromLocation() throws {
        let location = Location(name: "Copenhagen", latitude: 55.6713442, longitude: 12.523785)
        let url = try XCTUnwrap(WikipediaDeepLink.placesURL(for: location))
        let items = queryItems(url)
        XCTAssertEqual(items["lat"], "55.6713442")
        XCTAssertEqual(items["title"], "Copenhagen")
    }

    func testUsesDotDecimalSeparatorForNegativeCoordinate() throws {
        let url = try XCTUnwrap(WikipediaDeepLink.placesURL(latitude: 40.4380638, longitude: -3.7495758))
        XCTAssertEqual(queryItems(url)["lon"], "-3.7495758")
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
