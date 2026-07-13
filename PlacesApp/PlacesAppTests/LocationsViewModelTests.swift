import Testing
import Foundation
@testable import PlacesApp

@Suite("Locations view model")
@MainActor
struct LocationsViewModelTests {

    // MARK: - Loading

    @Test func loadSuccessPublishesLoadedState() async {
        let locations = [Location(name: "Amsterdam", latitude: 52.35, longitude: 4.83)]
        let viewModel = LocationsViewModel(service: MockService(locations: locations),
                                           opener: MockOpener())

        await viewModel.loadLocations()

        #expect(viewModel.state == .loaded(locations))
    }

    @Test func loadFailurePublishesFailedState() async {
        let viewModel = LocationsViewModel(service: MockService(shouldFail: true),
                                           opener: MockOpener())

        await viewModel.loadLocations()

        guard case .failed = viewModel.state else {
            Issue.record("Expected .failed, got \(viewModel.state)")
            return
        }
    }

    // MARK: - Opening feed locations

    @Test func openingLocationCallsOpenerWithDeepLink() async {
        let opener = MockOpener()
        let viewModel = LocationsViewModel(service: MockService(), opener: opener)
        let location = Location(name: "Mumbai", latitude: 19.08, longitude: 72.81)

        viewModel.open(location)
        await opener.waitForOpen()

        #expect(opener.openedURLs.first?.scheme == "wikipedia")
        #expect(opener.openedURLs.first?.host == "places")
    }

    @Test func openingLocationWhenWikipediaMissingSetsAlert() {
        let opener = MockOpener(canOpen: false)
        let viewModel = LocationsViewModel(service: MockService(), opener: opener)

        viewModel.open(Location(name: "X", latitude: 1, longitude: 2))

        #expect(viewModel.alert == .wikipediaNotInstalled)
        #expect(opener.openedURLs.isEmpty)
    }

    // MARK: - Custom location

    @Test func validCustomLocationOpens() async {
        let opener = MockOpener()
        let viewModel = LocationsViewModel(service: MockService(), opener: opener)

        let ok = viewModel.openCustomLocation(name: "Test", latitude: "1.5", longitude: "2.5")
        await opener.waitForOpen()

        #expect(ok)
        #expect(opener.openedURLs.count == 1)
        #expect(viewModel.alert == nil)
    }

    @Test func invalidCustomLatitudeSetsAlertAndDoesNotOpen() {
        let opener = MockOpener()
        let viewModel = LocationsViewModel(service: MockService(), opener: opener)

        let ok = viewModel.openCustomLocation(name: "", latitude: "abc", longitude: "2.5")

        #expect(!ok)
        #expect(viewModel.alert == .invalidCoordinates)
        #expect(opener.openedURLs.isEmpty)
    }

    @Test func outOfRangeCoordinateIsRejected() {
        let opener = MockOpener()
        let viewModel = LocationsViewModel(service: MockService(), opener: opener)

        let ok = viewModel.openCustomLocation(name: "", latitude: "200", longitude: "2.5")

        #expect(!ok)
        #expect(viewModel.alert == .invalidCoordinates)
    }

    // MARK: - CustomCoordinate

    @Test func customCoordinateTrimsWhitespace() {
        let coordinate = CustomCoordinate(latitude: "  52.35 ", longitude: " 4.83 ")
        #expect(coordinate == CustomCoordinate(latitude: "52.35", longitude: "4.83"))
    }

    @Test func customCoordinateRejectsBoundaryOverflow() {
        #expect(CustomCoordinate(latitude: "90.001", longitude: "0") == nil)
        #expect(CustomCoordinate(latitude: "90", longitude: "180") != nil)
    }
}

// MARK: - Test doubles

private enum SampleError: Error { case boom }

private struct MockService: LocationsServing {
    var locations: [Location] = []
    var shouldFail = false

    func fetchLocations() async throws -> [Location] {
        if shouldFail { throw SampleError.boom }
        return locations
    }
}

@MainActor
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
