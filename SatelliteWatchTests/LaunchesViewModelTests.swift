import Foundation
@testable import SatelliteWatch
import XCTest

@MainActor
final class LaunchesViewModelTests: XCTestCase {
    func testReplacesPageOnInitialLoad() async {
        let service = ControllableSpaceXService()
        service.launchesPages = [
            1: .fixture(
                docs: [Launch.fixture(id: "1"), Launch.fixture(id: "2")],
                page: 1,
                hasNextPage: true
            )
        ]

        let viewModel = LaunchesViewModel(service: service, pageSize: 2)
        await viewModel.loadInitial()

        XCTAssertEqual(viewModel.launches.map(\.id), ["1", "2"])
        XCTAssertTrue(viewModel.hasNextPage)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAppendsNextPageAndDeduplicates() async {
        let service = ControllableSpaceXService()
        service.launchesPages = [
            1: .fixture(
                docs: [Launch.fixture(id: "1"), Launch.fixture(id: "2")],
                page: 1,
                hasNextPage: true
            ),
            2: .fixture(
                docs: [Launch.fixture(id: "2"), Launch.fixture(id: "3")],
                page: 2,
                hasNextPage: false
            )
        ]

        let viewModel = LaunchesViewModel(service: service, pageSize: 2)
        await viewModel.loadInitial()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.launches.last)

        XCTAssertEqual(viewModel.launches.map(\.id), ["1", "2", "3"])
        XCTAssertFalse(viewModel.hasNextPage)
    }

    func testIgnoresAppendWhileLoadInFlight() async {
        let service = ControllableSpaceXService()
        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "1")], page: 1, hasNextPage: true),
            2: .fixture(docs: [Launch.fixture(id: "2")], page: 2, hasNextPage: false)
        ]

        let viewModel = LaunchesViewModel(service: service, pageSize: 1)
        await viewModel.loadInitial()

        service.parkFetches = true
        let item = viewModel.launches.last
        async let first: Void = viewModel.loadNextPageIfNeeded(currentItem: item)
        await waitUntil { service.launchFetchCount == 2 }
        async let second: Void = viewModel.loadNextPageIfNeeded(currentItem: item)
        service.parkFetches = false
        service.releaseParkedFetch()
        await first
        await second

        XCTAssertEqual(service.launchFetchCount, 2)
        XCTAssertEqual(viewModel.launches.map(\.id), ["1", "2"])
    }

    func testReplaceCancelsInFlightAppend() async {
        let service = ControllableSpaceXService()
        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "1")], page: 1, hasNextPage: true),
            2: .fixture(docs: [Launch.fixture(id: "2")], page: 2, hasNextPage: false)
        ]

        let viewModel = LaunchesViewModel(service: service, pageSize: 1)
        await viewModel.loadInitial()

        service.parkFetches = true
        let item = viewModel.launches.last
        async let append: Void = viewModel.loadNextPageIfNeeded(currentItem: item)
        await waitUntil { service.launchFetchCount == 2 }

        service.parkFetches = false
        service.launchesPages[1] = .fixture(
            docs: [Launch.fixture(id: "replaced")],
            page: 1,
            hasNextPage: false
        )
        await viewModel.loadInitial()
        await append

        XCTAssertEqual(viewModel.launches.map(\.id), ["replaced"])
    }

    func testPreservesRowsWhenAppendFails() async {
        let service = ControllableSpaceXService()
        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "1")], page: 1, hasNextPage: true)
        ]
        service.failOnPage = 2

        let viewModel = LaunchesViewModel(service: service, pageSize: 1)
        await viewModel.loadInitial()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.launches.last)

        XCTAssertEqual(viewModel.launches.map(\.id), ["1"])
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.hasNextPage)
        XCTAssertEqual(service.launchFetchCount, 2)

        service.failOnPage = nil
        service.launchesPages[2] = .fixture(
            docs: [Launch.fixture(id: "2")],
            page: 2,
            hasNextPage: false
        )
        await viewModel.retry()

        XCTAssertEqual(viewModel.launches.map(\.id), ["1", "2"])
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.hasNextPage)
        XCTAssertEqual(service.launchFetchCount, 3)
    }

    func testSurfacesErrorWhenInitialLoadFails() async {
        let service = ControllableSpaceXService()
        service.failOnPage = 1

        let viewModel = LaunchesViewModel(service: service)
        await viewModel.loadInitial()

        XCTAssertTrue(viewModel.launches.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testIgnoresStaleResponsesAfterNewerReplace() async {
        let service = ControllableSpaceXService()
        service.parkFetches = true
        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "slow")], page: 1, hasNextPage: false)
        ]

        let viewModel = LaunchesViewModel(service: service)
        async let slow: Void = viewModel.loadInitial()
        await waitUntil { service.launchFetchCount == 1 }

        service.parkFetches = false
        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "fast")], page: 1, hasNextPage: false)
        ]
        await viewModel.loadInitial()
        await slow

        XCTAssertEqual(viewModel.launches.map(\.id), ["fast"])
    }

    func testRetryReloadsEmptyState() async {
        let service = ControllableSpaceXService()
        service.failOnPage = 1

        let viewModel = LaunchesViewModel(service: service)
        await viewModel.loadInitial()
        XCTAssertNotNil(viewModel.errorMessage)

        service.failOnPage = nil
        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "recovered")], page: 1, hasNextPage: false)
        ]
        await viewModel.retry()

        XCTAssertEqual(viewModel.launches.map(\.id), ["recovered"])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAppliesAndClearsDateFilter() async {
        let service = ControllableSpaceXService()
        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "all")], page: 1, hasNextPage: false)
        ]

        let viewModel = LaunchesViewModel(service: service)
        await viewModel.loadInitial()

        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "filtered")], page: 1, hasNextPage: false)
        ]
        viewModel.draftStartDate = Date(timeIntervalSince1970: 1_600_000_000)
        viewModel.draftEndDate = Date(timeIntervalSince1970: 1_700_000_000)
        await viewModel.applyFilter()

        XCTAssertTrue(viewModel.hasActiveFilter)
        XCTAssertEqual(viewModel.launches.map(\.id), ["filtered"])
        XCTAssertNotNil(service.lastStartDate)
        XCTAssertNotNil(service.lastEndDate)

        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "cleared")], page: 1, hasNextPage: false)
        ]
        await viewModel.clearFilter()

        XCTAssertFalse(viewModel.hasActiveFilter)
        XCTAssertEqual(viewModel.launches.map(\.id), ["cleared"])
        XCTAssertNil(service.lastStartDate)
        XCTAssertNil(service.lastEndDate)
    }

    func testRejectsInvalidDraftFilterRange() async {
        let viewModel = LaunchesViewModel(service: ControllableSpaceXService())
        viewModel.draftStartDate = Date(timeIntervalSince1970: 2_000_000_000)
        viewModel.draftEndDate = Date(timeIntervalSince1970: 1_000_000_000)

        XCTAssertFalse(viewModel.canApplyDraftFilter)
        await viewModel.applyFilter()
        XCTAssertFalse(viewModel.hasActiveFilter)
    }
}
