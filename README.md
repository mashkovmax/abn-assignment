# Wikipedia Places — iOS Assignment

Author: **Max Mashkov**

This repository contains two things:

| Folder | What it is |
| ------ | ---------- |
| [`PlacesApp/`](PlacesApp) | A small **SwiftUI** test app that lists locations and opens them in Wikipedia. |
| [`wikipedia-ios/`](wikipedia-ios) | A local copy of the official [wikimedia/wikipedia-ios](https://github.com/wikimedia/wikipedia-ios) app, **modified** so it can be deep-linked straight to the *Places* tab centered on a given coordinate. |

The two apps talk to each other over a custom URL scheme (`wikipedia://`).

---

## The feature

Out of the box the Wikipedia app can be opened on its Places tab via
`wikipedia://places` and, optionally, centered on an **article**
(`wikipedia://places?WMFArticleURL=…`).

This assignment adds the ability to open Places centered on an **arbitrary
coordinate** supplied by the calling app:

```
wikipedia://places?lat=<latitude>&lon=<longitude>&title=<optional name>
```

Example:

```
wikipedia://places?lat=52.3547498&lon=4.8339215&title=Amsterdam
```

Opening that URL launches Wikipedia, switches to the Places tab, and centers the
map on Amsterdam (loading the top articles around it) instead of the user's
current location.

---

## Part 1 — PlacesApp (SwiftUI)

A minimal app that demonstrates the feature.

- Fetches locations from
  `https://raw.githubusercontent.com/abnamrocoesd/assignment-ios/main/locations.json`
  using `async`/`await`.
- Shows them in a `List`. Some feed entries have **no name** — those fall back to
  showing their coordinates.
- **Tapping a location** opens the Wikipedia app at that coordinate.
- The **＋** button lets the user enter a **custom location** (name optional,
  latitude/longitude validated) and open Wikipedia there.
- Pull-to-refresh, loading/error states with retry, and a clear alert if the
  Wikipedia app isn't installed.

### Architecture

MVVM, kept deliberately small and testable:

```
PlacesApp/
  Models/          Location, LocationsResponse (Codable, lat/long → latitude/longitude)
  Networking/      LocationsServing protocol + LocationsService (async URLSession)
  Deeplink/        WikipediaDeepLink (pure URL builder) + URLOpening abstraction
  ViewModels/      LocationsViewModel (@Observable, @MainActor)
  Views/           LocationsListView, CustomLocationView
```

- **Swift Concurrency:** networking is `async`/`await`; loading is a structured
  child of SwiftUI's `.task`, so cancellation propagates. The view model is
  `@MainActor` and uses the Observation framework (`@Observable`). Models are
  `Sendable`.
- **Accessibility:** each row is a single combined VoiceOver element with a label
  and an action hint; controls have explicit labels; Dynamic Type is respected.
- **Testability:** both the network (`LocationsServing`) and URL opening
  (`URLOpening`) are protocols, so the view model is tested with mocks — no
  network or `UIApplication` needed.

### Running it

```bash
cd PlacesApp
xcodegen generate      # only needed if PlacesApp.xcodeproj is missing / to regenerate
open PlacesApp.xcodeproj
```

Then run the **PlacesApp** scheme on an iOS 17+ simulator.

> The `.xcodeproj` is generated from [`project.yml`](PlacesApp/project.yml) with
> [XcodeGen](https://github.com/yonyz/XcodeGen). It is committed, so you can open
> and run without installing anything; regenerate only if you change `project.yml`.

### Tests

```bash
cd PlacesApp
xcodebuild -scheme PlacesApp -project PlacesApp.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Covered:
- JSON decoding, including the entry **without a name** and the `lat`/`long` key mapping.
- `WikipediaDeepLink` URL construction (scheme/host, query items, title encoding,
  locale-independent decimal formatting).
- Coordinate validation (range checks, whitespace trimming).
- View-model loading (success/failure) and open behavior, using mocks.

---

## Part 2 — Wikipedia app changes

The change follows the app's existing deep-link pipeline
(`NSUserActivity` → `WMFAppViewController` → `PlacesViewController`). Four files:

1. **`Wikipedia/Code/NSUserActivity+WMFExtensions.m`** — `wmf_placesActivityWithURL:`
   now also parses `lat`, `lon`, and optional `title` query items and, when a valid
   coordinate is present, stashes them in the activity's `userInfo`
   (`WMFLatitude` / `WMFLongitude` / `WMFLocationName`). Parsing uses an
   `en_US_POSIX` number formatter so `.`-separated decimals are always accepted.

2. **`Wikipedia/Code/WMFAppViewController.swift`** — the `.places` case of
   `processUserActivity` reads that coordinate and, when present, calls the new
   `PlacesViewController.showLocation(withLatitude:longitude:name:)` instead of the
   article-based path.

3. **`Wikipedia/Code/PlacesViewController.swift`** — new
   `showLocation(withLatitude:longitude:name:)`. It builds a 10 km region around the
   coordinate, sets the map region, and runs a location search there. It also sets
   `panMapToNextLocationUpdate = false` so the first Core Location update does **not**
   snap the map back to the user's location. This mirrors the existing
   `zoomAndPanMapView(toLocation:)` + `performDefaultSearch(withRegion:)` behavior.

4. **`docs/url_schemes.md`** — documents the new coordinate deep link.

### Trying the deep link directly

With the Wikipedia app installed on a simulator:

```bash
xcrun simctl openurl booted "wikipedia://places?lat=52.3547498&lon=4.8339215&title=Amsterdam"
```

### Building Wikipedia

The upstream project needs a one-time signing config generated (safe defaults, no
prompt):

```bash
cd wikipedia-ios
scripts/setup_bundle_id ci
xcodebuild -scheme Wikipedia -project Wikipedia.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGNING_ALLOWED=NO build
```

---

## Notes

- The assignment brief lists the feed URL under the `assignmentios` repo, but the
  file is actually served from **`assignment-ios`** (with a hyphen) — that is the URL
  the app uses.
- `wikipedia-ios/` is a vendored copy of the upstream app at clone time; the
  deep-link feature is the only functional change. Upstream lives at
  <https://github.com/wikimedia/wikipedia-ios>.
