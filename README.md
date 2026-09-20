# SatelliteWatch

[![Tests](https://github.com/isonka/SatelliteWatch/actions/workflows/tests.yml/badge.svg)](https://github.com/isonka/SatelliteWatch/actions/workflows/tests.yml)

iOS SwiftUI app for SpaceX launches and rockets. Swift 6, Observation, URLSession, no third-party libraries.

## Requirements

- Xcode 16+
- iOS 17+

Open `SatelliteWatch.xcodeproj` and run the **SatelliteWatch** scheme.

## Quick start for reviewers
The SpaceX API is archived and currently returns HTTP 525.
To see live data: Run (Debug) → toolbar data-source menu → Launch Library 2.
Offline: choose Sample data (also used by UI tests).

## Architecture

```
App/                      AppDependencies, DataSourceMode
Core/Networking/          SpaceXAPIClient, LaunchLibraryAPIClient, shared protocol
Core/Models/              Launch, Rocket, Launchpad, PaginatedResponse
Core/Presentation/        PaginatedListViewModel
Core/Design/              Tokens, state views, RemoteImageLoader
Features/Launches/        List, date filter, detail, rocket-card fallback fetch
Features/Rockets/         List and detail
PreviewContent/           MockSpaceXService
```

Both providers implement `SpaceXServiceProtocol`. `AppDependencies` picks the client and injects it at the app root. Tabs each own a `NavigationStack`. Lists get view models from `ContentView`. Launch detail reads the service from the environment when a launch only has a rocket id.

## Data sources

The assignment targets the public [SpaceX API](https://github.com/r-spacex/SpaceX-API) (`api.spacexdata.com`). That project is **archived and unmaintained**. The origin currently fails every request with **HTTP 525** (Cloudflare SSL handshake), so a Release build that only talks to SpaceX shows an error screen.

[Launch Library 2](https://thespacedevs.com/llapi) is the working backup: same launches/rockets domain, still free, and it still serves images. It is **opt-in**, not an automatic failover — Debug toolbar or `-mirrorData` — so the app still implements the assigned SpaceX client, and a reviewer can switch when that API is dark.

| Mode | When | Client |
|------|------|--------|
| SpaceX API | Default. Release always. | `SpaceXAPIClient` → `https://api.spacexdata.com` |
| Launch Library 2 | Debug menu or `-mirrorData` | `LaunchLibraryAPIClient` → `https://ll.thespacedevs.com` |
| Sample data | Debug menu or `-sampleData` | `MockSpaceXService` (Starlink 6-1, Crew-10, Falcon 9) |

UI tests pass `-sampleData`.

## SpaceX API

Assigned contract. Endpoints below are what the live client still encodes; they do not succeed while the origin returns 525.

| Resource | Endpoint |
|----------|----------|
| Launches | `POST /v5/launches/query` |
| Rockets | `POST /v4/rockets/query` |
| Rocket by id | `GET /v4/rockets/{id}` |

Launch queries populate `rocket` and `launchpad`, sort `date_utc` desc, page size 20. Date filter encodes inclusive **local calendar days** as UTC `$gte` / `$lte`.

When the API was up, `/v4/rockets` returned only a handful of vehicles (~4). Infinite scroll cannot be shown against that catalog. Pagination is covered by unit tests with multi-page stubs.

## Launch Library 2

Backup because SpaceX is archived (525), not because we needed a second pagination demo. Anonymous quota is **15 requests / hour**.

Each snapshot reload costs **3 GETs**, in parallel where possible, then pages in memory. The client does not follow `next`.

| Resource | Endpoint |
|----------|----------|
| Upcoming | `GET /2.2.0/launch/upcoming/?lsp__id=121&limit=100` |
| Previous | `GET /2.2.0/launch/previous/?lsp__id=121&limit=100` |
| Rockets | `GET /2.2.0/config/launcher/?manufacturer__name=SpaceX&limit=20&mode=detailed` |

DTOs map into the same `Launch` / `Rocket` types. Snapshot lives in memory and on disk (1-hour TTL). Scroll and date filter after a load are free. Pull-to-refresh inside the TTL returns the cached snapshot.

SpaceX launcher configs are ~13 rows, still one client page at `limit=20`. Use the **launches** list to demo infinite scroll on this source. Rocket paging stays a unit-test story.

Mirror mapping is lossy vs SpaceX: engine count/type/version is not on the launcher payload (`engines` is nil, so Rocket Detail hides that row), `type` is the family name, and a single `image_url` is stored as `flickrImages`.

## Decisions

**Detail screens are snapshot views.** `LaunchDetailView` and `RocketDetailView` render the value passed from the list (or from a one-shot `fetchRocket` fallback). They do not refresh, and they do not map every API field (height, mass, first flight, cost per launch are omitted). The assignment asks for name, type, description, active state, and engines.

**Unpopulated rocket on a launch:** if the list payload has only a rocket id, the launch detail card calls `fetchRocket(id:)` instead of showing “unavailable.”

**Paging:** one in-flight request, id dedupe, ignore stale generations, keep rows when an append fails. The inline error has a **Retry** footer that calls `retry()`; scrolling the last rows still works as a second path. SwiftUI `.task` cancellation ends the load when the list leaves the hierarchy for good. We do **not** cancel on `.onDisappear` (that also fires when pushing a detail or switching tabs).

**Rocket Detail launches:** the screen lists launches already loaded in `LaunchesViewModel` that reference this rocket. That set follows the current date filter and whatever pages have been fetched. It is not a per-rocket API query.

**Images:** `RemoteImageLoader` (in-memory cache, downsampled). Not `AsyncImage`.

**English UI copy** is inline. No String Catalog

**Swift 6** language mode on app and test targets.

## Tests

```bash
xcodebuild -project SatelliteWatch.xcodeproj \
  -scheme SatelliteWatch \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

Unit tests inject `ControllableSpaceXService` or a stub HTTP transport (SpaceX and Launch Library). UI tests launch with `-sampleData` and do not hit the network for lists.
