import Foundation
@testable import SatelliteWatch
import Testing

@MainActor
struct RocketsViewModelTests {
    @Test func replacesPageOnInitialLoad() async {
        let service = ControllableSpaceXService()
        service.rocketsPages = [
            1: .fixture(
                docs: [Rocket.fixture(id: "a"), Rocket.fixture(id: "b")],
                page: 1,
                hasNextPage: true
            )
        ]

        let viewModel = PaginatedListViewModel<Rocket>(service: service, pageSize: 2)
        await viewModel.loadInitial()

        #expect(viewModel.items.map(\.id) == ["a", "b"])
        #expect(viewModel.hasNextPage)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func appendsNextPageAndDeduplicates() async {
        let service = ControllableSpaceXService()
        service.rocketsPages = [
            1: .fixture(docs: [Rocket.fixture(id: "a")], page: 1, hasNextPage: true),
            2: .fixture(
                docs: [Rocket.fixture(id: "a"), Rocket.fixture(id: "b")],
                page: 2,
                hasNextPage: false
            )
        ]

        let viewModel = PaginatedListViewModel<Rocket>(service: service, pageSize: 1)
        await viewModel.loadInitial()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.items.last)

        #expect(viewModel.items.map(\.id) == ["a", "b"])
        #expect(viewModel.hasNextPage == false)
    }

    @Test func ignoresAppendWhileLoadInFlight() async {
        let service = ControllableSpaceXService()
        service.delayNanoseconds = 150_000_000
        service.rocketsPages = [
            1: .fixture(docs: [Rocket.fixture(id: "a")], page: 1, hasNextPage: true),
            2: .fixture(docs: [Rocket.fixture(id: "b")], page: 2, hasNextPage: false)
        ]

        let viewModel = PaginatedListViewModel<Rocket>(service: service, pageSize: 1)
        await viewModel.loadInitial()

        let item = viewModel.items.last
        async let first: Void = viewModel.loadNextPageIfNeeded(currentItem: item)
        async let second: Void = viewModel.loadNextPageIfNeeded(currentItem: item)
        await first
        await second

        #expect(viewModel.items.map(\.id) == ["a", "b"])
    }

    @Test func preservesRowsWhenAppendFails() async {
        let service = ControllableSpaceXService()
        service.rocketsPages = [
            1: .fixture(docs: [Rocket.fixture(id: "a")], page: 1, hasNextPage: true)
        ]
        service.failOnPage = 2

        let viewModel = PaginatedListViewModel<Rocket>(service: service, pageSize: 1)
        await viewModel.loadInitial()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.items.last)

        #expect(viewModel.items.map(\.id) == ["a"])
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.hasNextPage)
    }
}
