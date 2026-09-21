# SatelliteWatch

[![Tests](https://github.com/isonka/SatelliteWatch/actions/workflows/tests.yml/badge.svg)](https://github.com/isonka/SatelliteWatch/actions/workflows/tests.yml)

iOS SwiftUI app for SpaceX launches and rockets. Swift 6, Observation, URLSession, no third-party libraries.

## Requirements

- Xcode 16+
- iOS 17+

Open `SatelliteWatch.xcodeproj` and run the **SatelliteWatch** scheme.

## Quick start for reviewers
The SpaceX API is archived and currently returns HTTP 525.

**Debug Run uses Launch Library 2 by default** so a fresh clone shows data immediately.
Anonymous LL2 is **15 requests/hour**. Paging, refresh, and rocket-by-id all count.
Switch sources from the Launches toolbar menu (SpaceX API / Launch Library 2 / Sample data).
Engine details (`9 × merlin 1D+`) and a populated rocket with no extra GET are **Sample-only**: toolbar → Sample data, or `-sampleData`.
Release builds always use the SpaceX API client.

## Architecture

```
App/                      AppDependencies, DataSourceMode
Core/Networking/          HTTPClient, SpaceXAPIClient, LaunchLibraryAPIClient, shared protocol
Core/Models/              Launch, Rocket, Launchpad, PaginatedResponse
Core/Presentation/        PaginatedListViewModel
Core/Design/              Tokens, state views, RemoteImageLoader
Features/Launches/        List, date filter, detail, rocket-card fallback fetch
Features/Rockets/         List and detail
PreviewContent/           MockSpaceXService
```

Both providers implement `SpaceXServiceProtocol`. `AppDependencies` picks the client at the app root. Tabs each own a `NavigationStack` with Launch/Rocket destinations on the stack root. Lists and details receive view models and the service as arguments.

## Data sources

The assignment targets the public [SpaceX API](https://github.com/r-spacex/SpaceX-API) (`api.spacexdata.com`). That project is **archived and unmaintained**. The origin currently fails every request with **HTTP 525** (Cloudflare SSL handshake), so a Release build that only talks to SpaceX shows an error screen.

[Launch Library 2](https://thespacedevs.com/llapi) is the working backup: same launches/rockets domain, still free, and it still serves images. **Debug defaults to it** (or `-mirrorData`). Release always uses SpaceX so the assigned client stays the shipping path. Toolbar switch is manual — not automatic failover on 525.

| Mode | When | Client |
|------|------|--------|
| Launch Library 2 | Debug default; menu or `-mirrorData` | `LaunchLibraryAPIClient` → `https://ll.thespacedevs.com` |
| SpaceX API | Release always; Debug menu | `SpaceXAPIClient` → `https://api.spacexdata.com` |
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

Backup because SpaceX is archived (525). **Debug defaults to it** (or `-mirrorData`).

Paging matches the SpaceX client: `page` / `limit` from the list VM become `limit` + `offset=(page-1)*limit`. `hasNextPage` comes from the origin `next` URL, not an in-memory slice. Both APIs share `HTTPClient` (transport, status mapping, decode).

| Resource | Endpoint |
|----------|----------|
| Launches | `GET /2.2.0/launch/?lsp__id=121&limit=&offset=&ordering=-net&mode=detailed` |
| Launch date filter | `net__gte` / `net__lte` (same local-day UTC bounds as SpaceX) |
| Rockets | `GET /2.2.0/config/launcher/?manufacturer__name=SpaceX&limit=&offset=&mode=detailed` |
| Rocket by id | `GET /2.2.0/config/launcher/{id}/` |

DTOs map into the same `Launch` / `Rocket` types. `upcoming` is derived from launch status (no outcome yet). Lists load from `.task`.

Mirror mapping is lossy vs SpaceX: engine count/type/version is not on the launcher payload (`engines` is nil, so Rocket Detail shows “Not provided by this data source”), `type` is the family name, and a single `image_url` is stored as `flickrImages`.

## Decisions

**Detail screens are snapshot views.** `LaunchDetailView` and `RocketDetailView` render the value passed from the list (or from a one-shot `fetchRocket` fallback). They do not refresh, and they do not map every API field (height, mass, first flight, cost per launch are omitted). The assignment asks for name, type, description, active state, and engines.

**Unpopulated rocket on a launch:** if the list payload has only a rocket id, the launch detail card calls `fetchRocket(id:)` instead of showing “unavailable.”

**Paging:** one in-flight request, id dedupe, ignore stale generations, keep rows when an append fails. The inline error has a **Retry** footer that calls `retry()`; scrolling the last rows still works as a second path. SwiftUI `.task` cancellation ends the load when the list leaves the hierarchy for good.

**Rocket Detail launches:** section titled “From loaded launches” — launches already in `LaunchesViewModel` that reference this rocket. Follows the current date filter and fetched pages. Not a per-rocket API query.

**Caching:** `HTTPClient` uses a `URLSession` with `URLCache`. Launch Library also memoizes `fetchRocket(id:)` so opening several Falcon 9 launches does not burn the 15 req/hour quota.

**Images:** `RemoteImageLoader` (in-memory cache, downsampled). Not `AsyncImage`.

**English UI copy** is inline. No String Catalog

**Swift 6** language mode on app and test targets.

## Tests

```bash
xcodebuild -project SatelliteWatch.xcodeproj \
  -scheme SatelliteWatch \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test
```

Unit tests inject `ControllableSpaceXService` or a stub HTTP transport (SpaceX and Launch Library). UI tests launch with `-sampleData` and do not hit the network for lists.
