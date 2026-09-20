import XCTest
@testable import SatelliteWatch

/// Covers the defensive branches in the Launch Library → domain mapping. These
/// are the paths a live API change would hit first, so they are pinned
/// explicitly rather than left to the happy-path fixtures.
final class LaunchLibraryMappingTests: XCTestCase {
    private func launches(
        from json: String,
        upcoming: Bool = false
    ) throws -> [Launch] {
        let response = try SpaceXJSONDecoderFactory.make().decode(
            LaunchLibraryListResponse<LaunchLibraryLaunchDTO>.self,
            from: Data(json.utf8)
        )
        return response.results.map { Launch(library: $0, upcoming: upcoming) }
    }

    private func rockets(from json: String) throws -> [Rocket] {
        let response = try SpaceXJSONDecoderFactory.make().decode(
            LaunchLibraryListResponse<LaunchLibraryRocketDTO>.self,
            from: Data(json.utf8)
        )
        return response.results.map(Rocket.init(library:))
    }

    // MARK: - Success flag

    func testKnownStatusIDsDecideTheOutcome() throws {
        let mapped = try launches(from: LaunchLibraryEdgeCaseFixtures.launchesWithFailureStatusIDs)

        XCTAssertEqual(mapped.map(\.id), ["status-4", "status-7"])
        XCTAssertEqual(mapped[0].success, false)
        XCTAssertEqual(mapped[1].success, false)
    }

    func testUnknownStatusIDFallsBackToTheTextualAbbreviation() throws {
        let mapped = try launches(from: LaunchLibraryEdgeCaseFixtures.launchesWithUnknownStatusIDs)
        let byID = Dictionary(uniqueKeysWithValues: mapped.map { ($0.id, $0) })

        XCTAssertEqual(byID["abbrev-success"]?.success, true)
        XCTAssertEqual(byID["abbrev-failure"]?.success, false)
        XCTAssertEqual(byID["abbrev-partial"]?.success, false)
        XCTAssertNil(byID["abbrev-unknown"]?.success)
    }

    func testAbbreviationMatchingIgnoresCase() throws {
        // The "partial failure" fixture is lower-cased on the wire.
        let mapped = try launches(from: LaunchLibraryEdgeCaseFixtures.launchesWithUnknownStatusIDs)
        let partial = try XCTUnwrap(mapped.first { $0.id == "abbrev-partial" })

        XCTAssertEqual(partial.success, false)
    }

    func testUpcomingLaunchesNeverCarryAnOutcome() throws {
        // Even a payload that reports "Success" must map to nil while upcoming.
        let mapped = try launches(
            from: LaunchLibraryEdgeCaseFixtures.launchesWithUnknownStatusIDs,
            upcoming: true
        )

        XCTAssertTrue(mapped.allSatisfy { $0.success == nil })
        XCTAssertTrue(mapped.allSatisfy(\.upcoming))
    }

    // MARK: - Launchpad

    func testMissingOrEmptyPadCollapsesToUnknownReference() throws {
        let mapped = try launches(from: LaunchLibraryEdgeCaseFixtures.launchesWithoutUsablePads)

        XCTAssertEqual(mapped.map(\.launchpad), [.id("unknown"), .id("unknown")])
        XCTAssertTrue(mapped.allSatisfy { $0.launchSiteName == "Unknown launch site" })
    }

    func testPadWithOnlyANameStillProducesAPopulatedSite() throws {
        let mapped = try launches(from: LaunchLibraryJSONFixtures.previousLaunches)
        let launch = try XCTUnwrap(mapped.first)

        XCTAssertEqual(launch.launchSiteName, "SLC-40")
    }

    // MARK: - Patch selection

    func testHighestPriorityMissionPatchWins() throws {
        let mapped = try launches(from: LaunchLibraryEdgeCaseFixtures.launchesWithCompetingPatches)
        let prioritised = try XCTUnwrap(mapped.first { $0.id == "patch-priority" })

        XCTAssertEqual(prioritised.links?.patch?.small, "https://example.com/high.png")
        XCTAssertEqual(prioritised.patchImageURL?.absoluteString, "https://example.com/high.png")
    }

    func testTopLevelImageIsUsedWhenNoMissionPatchExists() throws {
        let mapped = try launches(from: LaunchLibraryEdgeCaseFixtures.launchesWithCompetingPatches)
        let fallback = try XCTUnwrap(mapped.first { $0.id == "patch-fallback" })

        XCTAssertEqual(fallback.patchImageURL?.absoluteString, "https://example.com/fallback.png")
    }

    // MARK: - Rockets

    func testSuccessRateIsComputedFromLaunchCounts() throws {
        let mapped = try rockets(from: LaunchLibraryJSONFixtures.rockets)

        XCTAssertEqual(mapped[0].successRatePct, 98)
        XCTAssertEqual(mapped[1].successRatePct, 100)
    }

    func testSuccessRateIsNilWhenItCannotBeComputed() throws {
        let mapped = try rockets(from: LaunchLibraryEdgeCaseFixtures.rocketsWithUncomputableSuccessRate)

        XCTAssertEqual(mapped.map(\.name), ["Never Flown", "Unknown Total", "Unknown Successes"])
        XCTAssertTrue(
            mapped.allSatisfy { $0.successRatePct == nil },
            "Zero, missing total, and missing successes must not divide"
        )
    }

    func testRocketNamePrefersFullName() throws {
        let mapped = try rockets(from: LaunchLibraryJSONFixtures.rockets)
        XCTAssertEqual(mapped[0].name, "Falcon 9 Block 5")

        let withoutFullName = try rockets(
            from: LaunchLibraryEdgeCaseFixtures.rocketsWithUncomputableSuccessRate
        )
        XCTAssertEqual(withoutFullName[0].name, "Never Flown")
    }

    func testLibraryRocketsNeverClaimEngineDetail() throws {
        let mapped = try rockets(from: LaunchLibraryJSONFixtures.rockets)

        XCTAssertTrue(mapped.allSatisfy { $0.engines == nil })
        XCTAssertEqual(mapped[0].enginesDisplayText, "Not provided by this data source")
    }

    // MARK: - Date precision

    func testLibraryPrecisionAbbreviationsMapToDomainPrecision() {
        XCTAssertEqual(DatePrecision(libraryAbbrev: "SEC"), .hour)
        XCTAssertEqual(DatePrecision(libraryAbbrev: "MIN"), .hour)
        XCTAssertEqual(DatePrecision(libraryAbbrev: "HOUR"), .hour)
        XCTAssertEqual(DatePrecision(libraryAbbrev: "day"), .day)
        XCTAssertEqual(DatePrecision(libraryAbbrev: "WEEK"), .month)
        XCTAssertEqual(DatePrecision(libraryAbbrev: "MONTH"), .month)
        XCTAssertEqual(DatePrecision(libraryAbbrev: "QTR"), .quarter)
        XCTAssertEqual(DatePrecision(libraryAbbrev: "HALF"), .half)
        XCTAssertEqual(DatePrecision(libraryAbbrev: "YEAR"), .year)
        XCTAssertEqual(DatePrecision(libraryAbbrev: "DEC"), .year)
        XCTAssertNil(DatePrecision(libraryAbbrev: "NOPE"))
        XCTAssertNil(DatePrecision(libraryAbbrev: nil))
    }

    // MARK: - Links

    func testMissionLinksDecodeFromBothStringAndObjectShapes() throws {
        // Live LL2 puts `infoURLs` / `vidURLs` on the launch, not the mission.
        let mapped = try launches(from: LaunchLibraryJSONFixtures.upcomingLaunches, upcoming: true)
        let launch = try XCTUnwrap(mapped.first)

        XCTAssertEqual(launch.links?.article, "https://example.com/info")
        XCTAssertEqual(launch.links?.webcast, "https://example.com/vid")
    }
}
