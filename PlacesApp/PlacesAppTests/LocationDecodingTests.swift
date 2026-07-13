import XCTest
@testable import PlacesApp

final class LocationDecodingTests: XCTestCase {

    /// Mirrors the real feed, including the final entry that has no `name`.
    private let sampleJSON = """
    {
      "locations": [
        { "name": "Amsterdam", "lat": 52.3547498, "long": 4.8339215 },
        { "name": "Mumbai", "lat": 19.0823998, "long": 72.8111468 },
        { "lat": 40.4380638, "long": -3.7495758 }
      ]
    }
    """.data(using: .utf8)!

    func testDecodesAllLocations() throws {
        let response = try JSONDecoder().decode(LocationsResponse.self, from: sampleJSON)
        XCTAssertEqual(response.locations.count, 3)
    }

    func testMapsLatLongKeys() throws {
        let response = try JSONDecoder().decode(LocationsResponse.self, from: sampleJSON)
        let amsterdam = response.locations[0]
        XCTAssertEqual(amsterdam.name, "Amsterdam")
        XCTAssertEqual(amsterdam.latitude, 52.3547498, accuracy: 0.0000001)
        XCTAssertEqual(amsterdam.longitude, 4.8339215, accuracy: 0.0000001)
    }

    func testDecodesEntryWithoutName() throws {
        let response = try JSONDecoder().decode(LocationsResponse.self, from: sampleJSON)
        let nameless = response.locations[2]
        XCTAssertNil(nameless.name)
        XCTAssertEqual(nameless.latitude, 40.4380638, accuracy: 0.0000001)
    }

    func testDisplayNameFallsBackToCoordinates() throws {
        let response = try JSONDecoder().decode(LocationsResponse.self, from: sampleJSON)
        XCTAssertEqual(response.locations[0].displayName, "Amsterdam")
        // Nameless entry shows its coordinate string instead.
        XCTAssertEqual(response.locations[2].displayName, "40.4381, -3.7496")
    }

    func testIDIsStableForSameLocation() {
        let a = Location(name: "X", latitude: 1, longitude: 2)
        let b = Location(name: "X", latitude: 1, longitude: 2)
        XCTAssertEqual(a.id, b.id)
    }
}
