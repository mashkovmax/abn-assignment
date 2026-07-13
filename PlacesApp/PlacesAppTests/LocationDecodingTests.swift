import Testing
import Foundation
@testable import PlacesApp

@Suite("Location decoding")
struct LocationDecodingTests {

    /// Mirrors the real feed, including the final entry that has no `name`.
    let sampleJSON = """
    {
      "locations": [
        { "name": "Amsterdam", "lat": 52.3547498, "long": 4.8339215 },
        { "name": "Mumbai", "lat": 19.0823998, "long": 72.8111468 },
        { "lat": 40.4380638, "long": -3.7495758 }
      ]
    }
    """.data(using: .utf8)!

    @Test func decodesAllLocations() throws {
        let response = try JSONDecoder().decode(LocationsResponse.self, from: sampleJSON)
        #expect(response.locations.count == 3)
    }

    @Test func mapsLatLongKeys() throws {
        let response = try JSONDecoder().decode(LocationsResponse.self, from: sampleJSON)
        let amsterdam = response.locations[0]
        #expect(amsterdam.name == "Amsterdam")
        #expect(abs(amsterdam.latitude - 52.3547498) < 0.0000001)
        #expect(abs(amsterdam.longitude - 4.8339215) < 0.0000001)
    }

    @Test func decodesEntryWithoutName() throws {
        let response = try JSONDecoder().decode(LocationsResponse.self, from: sampleJSON)
        let nameless = response.locations[2]
        #expect(nameless.name == nil)
        #expect(abs(nameless.latitude - 40.4380638) < 0.0000001)
    }

    @Test func displayNameFallsBackToCoordinates() throws {
        let response = try JSONDecoder().decode(LocationsResponse.self, from: sampleJSON)
        #expect(response.locations[0].displayName == "Amsterdam")
        // Nameless entry shows its coordinate string instead.
        #expect(response.locations[2].displayName == "40.4381, -3.7496")
    }

    @Test func idIsStableForSameLocation() {
        let a = Location(name: "X", latitude: 1, longitude: 2)
        let b = Location(name: "X", latitude: 1, longitude: 2)
        #expect(a.id == b.id)
    }
}
