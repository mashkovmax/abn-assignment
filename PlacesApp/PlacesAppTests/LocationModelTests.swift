import Testing
import Foundation
@testable import PlacesApp

@Suite("Location model")
struct LocationModelTests {

    @Test func coordinateTextFormatsToFourDecimals() {
        let location = Location(name: nil, latitude: 52.3547498, longitude: 4.8339215)
        #expect(location.coordinateText == "52.3547, 4.8339")
    }

    @Test func coordinateTextHandlesNegatives() {
        let location = Location(name: nil, latitude: 40.4380638, longitude: -3.7495758)
        #expect(location.coordinateText == "40.4381, -3.7496")
    }

    @Test func displayNameUsesNameWhenPresent() {
        let location = Location(name: "Amsterdam", latitude: 1, longitude: 2)
        #expect(location.displayName == "Amsterdam")
    }

    @Test func displayNameFallsBackWhenNameNil() {
        let location = Location(name: nil, latitude: 1, longitude: 2)
        #expect(location.displayName == location.coordinateText)
    }

    @Test func displayNameFallsBackWhenNameEmpty() {
        let location = Location(name: "", latitude: 1, longitude: 2)
        #expect(location.displayName == location.coordinateText)
    }

    @Test func idDiffersByCoordinate() {
        let a = Location(name: "X", latitude: 1, longitude: 2)
        let b = Location(name: "X", latitude: 3, longitude: 4)
        #expect(a.id != b.id)
    }

    @Test func idDiffersByName() {
        let a = Location(name: "X", latitude: 1, longitude: 2)
        let b = Location(name: "Y", latitude: 1, longitude: 2)
        #expect(a.id != b.id)
    }

    @Test func encodesAndDecodesRoundTrip() throws {
        let original = Location(name: "Copenhagen", latitude: 55.6713442, longitude: 12.523785)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Location.self, from: data)
        #expect(decoded == original)
    }
}
