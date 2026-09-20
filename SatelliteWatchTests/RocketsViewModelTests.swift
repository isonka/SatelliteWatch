import Foundation
@testable import SatelliteWatch
import XCTest

@MainActor
final class RocketsViewModelTests: XCTestCase {
    func testReplacesPageOnInitialLoad() async {
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

        XCTAssertEqual(viewModel.items.map(\.id), ["a", "b"])
        XCTAssertTrue(viewModel.hasNextPage)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAppendsNextPageAndDeduplicates() async {
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

        XCTAssertEqual(viewModel.items.map(\.id), ["a", "b"])
        XCTAssertFalse(viewModel.hasNextPage)
    }

    func testIgnoresAppendWhileLoadInFlight() async {
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

        XCTAssertEqual(viewModel.items.map(\.id), ["a", "b"])
    }

    func testPreservesRowsWhenAppendFails() async {
        let service = ControllableSpaceXService()
        service.rocketsPages = [
            1: .fixture(docs: [Rocket.fixture(id: "a")], page: 1, hasNextPage: true)
        ]
        service.failOnPage = 2

        let viewModel = PaginatedListViewModel<Rocket>(service: service, pageSize: 1)
        await viewModel.loadInitial()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.items.last)

        XCTAssertEqual(viewModel.items.map(\.id), ["a"])
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.hasNextPage)
        XCTAssertEqual(service.rocketListFetchCount, 2)

        service.failOnPage = nil
        service.rocketsPages[2] = .fixture(
            docs: [Rocket.fixture(id: "b")],
            page: 2,
            hasNextPage: false
        )
        await viewModel.retry()

        XCTAssertEqual(viewModel.items.map(\.id), ["a", "b"])
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.hasNextPage)
        XCTAssertEqual(service.rocketListFetchCount, 3)
    }
}
