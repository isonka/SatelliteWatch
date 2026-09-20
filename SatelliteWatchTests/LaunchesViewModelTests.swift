import Foundation
@testable import SatelliteWatch
import Testing

@MainActor
struct LaunchesViewModelTests {
    @Test func replacesPageOnInitialLoad() async {
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

        #expect(viewModel.launches.map(\.id) == ["1", "2"])
        #expect(viewModel.hasNextPage)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func appendsNextPageAndDeduplicates() async {
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

        #expect(viewModel.launches.map(\.id) == ["1", "2", "3"])
        #expect(viewModel.hasNextPage == false)
    }

    @Test func ignoresAppendWhileLoadInFlight() async {
        let service = ControllableSpaceXService()
        service.delayNanoseconds = 150_000_000
        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "1")], page: 1, hasNextPage: true),
            2: .fixture(docs: [Launch.fixture(id: "2")], page: 2, hasNextPage: false)
        ]

        let viewModel = LaunchesViewModel(service: service, pageSize: 1)
        await viewModel.loadInitial()

        let item = viewModel.launches.last
        async let first: Void = viewModel.loadNextPageIfNeeded(currentItem: item)
        async let second: Void = viewModel.loadNextPageIfNeeded(currentItem: item)
        await first
        await second

        #expect(service.launchFetchCount == 2)
        #expect(viewModel.launches.map(\.id) == ["1", "2"])
    }

    @Test func replaceCancelsInFlightAppend() async {
        let service = ControllableSpaceXService()
        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "1")], page: 1, hasNextPage: true),
            2: .fixture(docs: [Launch.fixture(id: "2")], page: 2, hasNextPage: false)
        ]

        let viewModel = LaunchesViewModel(service: service, pageSize: 1)
        await viewModel.loadInitial()

        service.delayNanoseconds = 200_000_000
        let item = viewModel.launches.last
        async let append: Void = viewModel.loadNextPageIfNeeded(currentItem: item)

        service.delayNanoseconds = 0
        service.launchesPages[1] = .fixture(
            docs: [Launch.fixture(id: "replaced")],
            page: 1,
            hasNextPage: false
        )
        await viewModel.loadInitial()
        await append

        #expect(viewModel.launches.map(\.id) == ["replaced"])
    }

    @Test func preservesRowsWhenAppendFails() async {
        let service = ControllableSpaceXService()
        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "1")], page: 1, hasNextPage: true)
        ]
        service.failOnPage = 2

        let viewModel = LaunchesViewModel(service: service, pageSize: 1)
        await viewModel.loadInitial()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.launches.last)

        #expect(viewModel.launches.map(\.id) == ["1"])
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.hasNextPage)
        #expect(service.launchFetchCount == 2)

        service.failOnPage = nil
        service.launchesPages[2] = .fixture(
            docs: [Launch.fixture(id: "2")],
            page: 2,
            hasNextPage: false
        )
        await viewModel.retry()

        #expect(viewModel.launches.map(\.id) == ["1", "2"])
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.hasNextPage == false)
        #expect(service.launchFetchCount == 3)
    }

    @Test func surfacesErrorWhenInitialLoadFails() async {
        let service = ControllableSpaceXService()
        service.failOnPage = 1

        let viewModel = LaunchesViewModel(service: service)
        await viewModel.loadInitial()

        #expect(viewModel.launches.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func ignoresStaleResponsesAfterNewerReplace() async {
        let service = ControllableSpaceXService()
        service.delayNanoseconds = 200_000_000
        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "slow")], page: 1, hasNextPage: false)
        ]

        let viewModel = LaunchesViewModel(service: service)
        async let slow: Void = viewModel.loadInitial()

        service.delayNanoseconds = 0
        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "fast")], page: 1, hasNextPage: false)
        ]
        await viewModel.loadInitial()
        await slow

        #expect(viewModel.launches.map(\.id) == ["fast"])
    }

    @Test func retryReloadsEmptyState() async {
        let service = ControllableSpaceXService()
        service.failOnPage = 1

        let viewModel = LaunchesViewModel(service: service)
        await viewModel.loadInitial()
        #expect(viewModel.errorMessage != nil)

        service.failOnPage = nil
        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "recovered")], page: 1, hasNextPage: false)
        ]
        await viewModel.retry()

        #expect(viewModel.launches.map(\.id) == ["recovered"])
        #expect(viewModel.errorMessage == nil)
    }

    @Test func appliesAndClearsDateFilter() async {
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

        #expect(viewModel.hasActiveFilter)
        #expect(viewModel.launches.map(\.id) == ["filtered"])
        #expect(service.lastStartDate != nil)
        #expect(service.lastEndDate != nil)

        service.launchesPages = [
            1: .fixture(docs: [Launch.fixture(id: "cleared")], page: 1, hasNextPage: false)
        ]
        await viewModel.clearFilter()

        #expect(viewModel.hasActiveFilter == false)
        #expect(viewModel.launches.map(\.id) == ["cleared"])
        #expect(service.lastStartDate == nil)
        #expect(service.lastEndDate == nil)
    }

    @Test func rejectsInvalidDraftFilterRange() async {
        let viewModel = LaunchesViewModel(service: ControllableSpaceXService())
        viewModel.draftStartDate = Date(timeIntervalSince1970: 2_000_000_000)
        viewModel.draftEndDate = Date(timeIntervalSince1970: 1_000_000_000)

        #expect(viewModel.canApplyDraftFilter == false)
        await viewModel.applyFilter()
        #expect(viewModel.hasActiveFilter == false)
    }
}
