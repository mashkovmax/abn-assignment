import XCTest
@testable import PlacesApp

@MainActor
final class LocationsViewModelTests: XCTestCase {

    // MARK: - Loading

    func testLoadSuccessPublishesLoadedState() async {
        let locations = [Location(name: "Amsterdam", latitude: 52.35, longitude: 4.83)]
        let viewModel = LocationsViewModel(service: MockService(result: .success(locations)),
                                           opener: MockOpener())

        await viewModel.loadLocations()

        XCTAssertEqual(viewModel.state, .loaded(locations))
    }

    func testLoadFailurePublishesFailedState() async {
        let viewModel = LocationsViewModel(service: MockService(result: .failure(SampleError.boom)),
                                           opener: MockOpener())

        await viewModel.loadLocations()

        guard case .failed = viewModel.state else {
            return XCTFail("Expected .failed, got \(viewModel.state)")
        }
    }

    // MARK: - Opening feed locations

    func testOpeningLocationCallsOpenerWithDeepLink() async {
        let opener = MockOpener()
        let viewModel = LocationsViewModel(service: MockService(result: .success([])), opener: opener)
        let location = Location(name: "Mumbai", latitude: 19.08, longitude: 72.81)

        viewModel.open(location)
        await opener.waitForOpen()

        XCTAssertEqual(opener.openedURLs.first?.scheme, "wikipedia")
        XCTAssertEqual(opener.openedURLs.first?.host, "places")
    }

    func testOpeningLocationWhenWikipediaMissingSetsAlert() {
        let opener = MockOpener(canOpen: false)
        let viewModel = LocationsViewModel(service: MockService(result: .success([])), opener: opener)

        viewModel.open(Location(name: "X", latitude: 1, longitude: 2))

        XCTAssertEqual(viewModel.alert, .wikipediaNotInstalled)
        XCTAssertTrue(opener.openedURLs.isEmpty)
    }

    // MARK: - Custom location

    func testValidCustomLocationOpens() async {
        let opener = MockOpener()
        let viewModel = LocationsViewModel(service: MockService(result: .success([])), opener: opener)

        let ok = viewModel.openCustomLocation(name: "Test", latitude: "1.5", longitude: "2.5")
        await opener.waitForOpen()

        XCTAssertTrue(ok)
        XCTAssertEqual(opener.openedURLs.count, 1)
        XCTAssertNil(viewModel.alert)
    }

    func testInvalidCustomLatitudeSetsAlertAndDoesNotOpen() {
        let opener = MockOpener()
        let viewModel = LocationsViewModel(service: MockService(result: .success([])), opener: opener)

        let ok = viewModel.openCustomLocation(name: "", latitude: "abc", longitude: "2.5")

        XCTAssertFalse(ok)
        XCTAssertEqual(viewModel.alert, .invalidCoordinates)
        XCTAssertTrue(opener.openedURLs.isEmpty)
    }

    func testOutOfRangeCoordinateIsRejected() {
        let opener = MockOpener()
        let viewModel = LocationsViewModel(service: MockService(result: .success([])), opener: opener)

        let ok = viewModel.openCustomLocation(name: "", latitude: "200", longitude: "2.5")

        XCTAssertFalse(ok)
        XCTAssertEqual(viewModel.alert, .invalidCoordinates)
    }

    // MARK: - CustomCoordinate

    func testCustomCoordinateTrimsWhitespace() {
        let coordinate = CustomCoordinate(latitude: "  52.35 ", longitude: " 4.83 ")
        XCTAssertEqual(coordinate, CustomCoordinate(latitude: "52.35", longitude: "4.83"))
    }

    func testCustomCoordinateRejectsBoundaryOverflow() {
        XCTAssertNil(CustomCoordinate(latitude: "90.001", longitude: "0"))
        XCTAssertNotNil(CustomCoordinate(latitude: "90", longitude: "180"))
    }
}

// MARK: - Test doubles

private enum SampleError: Error { case boom }

private struct MockService: LocationsServing {
    let result: Result<[Location], Error>
    func fetchLocations() async throws -> [Location] {
        try result.get()
    }
}

private final class MockOpener: URLOpening {
    private(set) var openedURLs: [URL] = []
    private let canOpenResult: Bool
    private var continuation: CheckedContinuation<Void, Never>?

    init(canOpen: Bool = true) {
        self.canOpenResult = canOpen
    }

    func canOpen(_ url: URL) -> Bool { canOpenResult }

    @discardableResult
    func open(_ url: URL) async -> Bool {
        openedURLs.append(url)
        continuation?.resume()
        continuation = nil
        return true
    }

    /// Awaits the next `open(_:)` call (the view model fires it in a detached Task).
    func waitForOpen() async {
        if !openedURLs.isEmpty { return }
        await withCheckedContinuation { continuation = $0 }
    }
}
