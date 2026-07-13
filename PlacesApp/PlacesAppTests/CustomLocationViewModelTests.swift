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

    // MARK: - Validation

    @Test func validatedLocationBuildsLocationFromValidInput() throws {
        let viewModel = makeViewModel()
        viewModel.name = "Test"
        viewModel.latitude = "1.5"
        viewModel.longitude = "2.5"

        let location = try #require(viewModel.validatedLocation())
        #expect(location.name == "Test")
        #expect(location.latitude == 1.5)
        #expect(location.longitude == 2.5)
        #expect(viewModel.validationMessage == nil)
    }

    @Test func validatedLocationHasNilNameWhenNameBlank() throws {
        let viewModel = makeViewModel()
        viewModel.latitude = "1"
        viewModel.longitude = "2"

        let location = try #require(viewModel.validatedLocation())
        #expect(location.name == nil)
    }

    @Test func validatedLocationRejectsInvalidCoordinatesAndSetsMessage() {
        let viewModel = makeViewModel()
        viewModel.latitude = "abc"
        viewModel.longitude = "2.5"

        #expect(viewModel.validatedLocation() == nil)
        #expect(viewModel.validationMessage != nil)
    }

    @Test func validatedLocationRejectsOutOfRange() {
        let viewModel = makeViewModel()
        viewModel.latitude = "200"
        viewModel.longitude = "2.5"

        #expect(viewModel.validatedLocation() == nil)
    }

    @Test func notFoundErrorHasDescription() {
        #expect(GeocodingError.notFound.errorDescription?.isEmpty == false)
    }

    // MARK: - Helper

    private func makeViewModel() -> CustomLocationViewModel {
        CustomLocationViewModel(geocoder: MockGeocoder(result: .failure(GeocodingError.notFound)))
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
