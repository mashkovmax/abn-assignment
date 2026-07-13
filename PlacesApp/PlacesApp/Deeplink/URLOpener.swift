import UIKit

/// Abstraction over opening URLs so the view model can be tested without
/// touching `UIApplication`.
///
/// Only the methods are `@MainActor` (not the whole protocol), so conforming
/// types aren't inferred to be main-actor-isolated and can be constructed
/// from a nonisolated context (e.g. as a default argument value).
protocol URLOpening {
    @MainActor func canOpen(_ url: URL) -> Bool
    @MainActor @discardableResult func open(_ url: URL) async -> Bool
}

/// Production implementation backed by `UIApplication`. The type itself is not
/// actor-isolated (so it can be created from anywhere, e.g. as a default value),
/// while its methods satisfy the `@MainActor` protocol requirements.
struct SystemURLOpener: URLOpening {
    func canOpen(_ url: URL) -> Bool {
        UIApplication.shared.canOpenURL(url)
    }

    @discardableResult
    func open(_ url: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            UIApplication.shared.open(url, options: [:]) { success in
                continuation.resume(returning: success)
            }
        }
    }
}
