import Testing
import Foundation
@testable import PlacesApp

@Suite("Custom location view model")
@MainActor
struct CustomLocationViewModelTests {

    @Test func lookUpFillsCoordinateFields() async {
        let place = GeocodedPlace(name: "Amsterdam", latitude: 52.3547498, longitude: 4.8339215)
        let viewModel = CustomLocationViewModel(geocoder: MockGeocoder(result: .success(place)))
        viewModel.name = "Amsterdam"

        await viewModel.lookUpCoordinates()

        #expect(viewModel.latitude == "52.3547498")
        #expect(viewModel.longitude == "4.8339215")
        #expect(viewModel.geocodeState == .idle)
    }

    @Test func lookUpFailureSetsFailedState() async {
        let viewModel = CustomLocationViewModel(geocoder: MockGeocoder(result: .failure(GeocodingError.notFound)))
        viewModel.name = "Nowhere-at-all"

        await viewModel.lookUpCoordinates()

        guard case .failed = viewModel.geocodeState else {
            Issue.record("Expected .failed, got \(viewModel.geocodeState)")
            return
        }
        #expect(viewModel.latitude.isEmpty)
    }

    @Test func lookUpDoesNothingForBlankName() async {
        let geocoder = MockGeocoder(result: .success(GeocodedPlace(name: nil, latitude: 1, longitude: 2)))
        let viewModel = CustomLocationViewModel(geocoder: geocoder)
        viewModel.name = "   "

        await viewModel.lookUpCoordinates()

        #expect(geocoder.callCount == 0)
        #expect(viewModel.latitude.isEmpty)
    }

    @Test func canLookUpReflectsName() {
        let viewModel = CustomLocationViewModel(geocoder: MockGeocoder(result: .failure(GeocodingError.notFound)))
        #expect(!viewModel.canLookUp)
        viewModel.name = "Paris"
        #expect(viewModel.canLookUp)
    }
}

// MARK: - Test double

private final class MockGeocoder: Geocoding, @unchecked Sendable {
    private let result: Result<GeocodedPlace, Error>
    private(set) var callCount = 0

    init(result: Result<GeocodedPlace, Error>) {
        self.result = result
    }

    func geocode(_ query: String) async throws -> GeocodedPlace {
        callCount += 1
        return try result.get()
    }
}
