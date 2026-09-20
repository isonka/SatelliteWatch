import XCTest
@testable import SatelliteWatch

@MainActor
final class LaunchesViewModelTests: XCTestCase {
    func testApplyFilterPassesDatesToService() async throws {
        let service = ControllableSpaceXService()
        service.enqueueLaunchResponse(.page([.fixture(id: "filtered")], page: 1))
        let viewModel = LaunchesViewModel(service: service)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2024, month: 1, day: 31))!

        viewModel.draftStartDate = start
        viewModel.draftEndDate = end
        await viewModel.applyFilter()

        XCTAssertTrue(viewModel.hasActiveFilter)
        XCTAssertEqual(viewModel.startDate, calendar.startOfDay(for: start))
        XCTAssertEqual(viewModel.endDate, calendar.startOfDay(for: end))
        XCTAssertNotNil(viewModel.activeFilterSummary)
        XCTAssertEqual(viewModel.launches.map(\.id), ["filtered"])

        let call = try XCTUnwrap(service.launchCalls.last)
        XCTAssertEqual(call.start, calendar.startOfDay(for: start))
        XCTAssertEqual(call.end, calendar.startOfDay(for: end))
    }

    func testClearFilterRemovesDatesAndReloads() async throws {
        let service = ControllableSpaceXService()
        service.enqueueLaunchResponse(.page([.fixture(id: "a")], page: 1))
        service.enqueueLaunchResponse(.page([.fixture(id: "b")], page: 1))
        let viewModel = LaunchesViewModel(service: service)

        viewModel.draftStartDate = Date(timeIntervalSince1970: 1_600_000_000)
        viewModel.draftEndDate = Date(timeIntervalSince1970: 1_700_000_000)
        await viewModel.applyFilter()
        XCTAssertTrue(viewModel.hasActiveFilter)

        await viewModel.clearFilter()

        XCTAssertFalse(viewModel.hasActiveFilter)
        XCTAssertNil(viewModel.startDate)
        XCTAssertNil(viewModel.endDate)
        XCTAssertNil(viewModel.activeFilterSummary)
        XCTAssertEqual(viewModel.launches.map(\.id), ["b"])

        let call = try XCTUnwrap(service.launchCalls.last)
        XCTAssertNil(call.start)
        XCTAssertNil(call.end)
    }

    func testCanApplyDraftFilterRequiresStartOnOrBeforeEnd() {
        let viewModel = LaunchesViewModel(service: ControllableSpaceXService())
        let calendar = Calendar.current

        viewModel.draftStartDate = calendar.date(from: DateComponents(year: 2024, month: 2, day: 1))!
        viewModel.draftEndDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        XCTAssertFalse(viewModel.canApplyDraftFilter)

        viewModel.draftEndDate = calendar.date(from: DateComponents(year: 2024, month: 3, day: 1))!
        XCTAssertTrue(viewModel.canApplyDraftFilter)
    }

    func testApplyFilterIgnoredWhenDraftInvalid() async {
        let service = ControllableSpaceXService()
        let viewModel = LaunchesViewModel(service: service)
        let calendar = Calendar.current

        viewModel.draftStartDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        viewModel.draftEndDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        await viewModel.applyFilter()

        XCTAssertTrue(service.launchCalls.isEmpty)
        XCTAssertFalse(viewModel.hasActiveFilter)
    }

    func testPrepareFilterDraftUsesActiveFilterWhenPresent() async {
        let service = ControllableSpaceXService()
        service.enqueueLaunchResponse(.page([], page: 1))
        let viewModel = LaunchesViewModel(service: service)
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2023, month: 5, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2023, month: 5, day: 10))!

        viewModel.draftStartDate = start
        viewModel.draftEndDate = end
        await viewModel.applyFilter()

        viewModel.draftStartDate = Date()
        viewModel.draftEndDate = Date()
        viewModel.prepareFilterDraft()

        XCTAssertEqual(viewModel.draftStartDate, calendar.startOfDay(for: start))
        XCTAssertEqual(viewModel.draftEndDate, calendar.startOfDay(for: end))
    }

    func testActiveFilterSummaryForDateRange() async throws {
        let service = ControllableSpaceXService()
        service.enqueueLaunchResponse(.page([], page: 1))
        let viewModel = LaunchesViewModel(service: service)
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2024, month: 1, day: 2))!

        viewModel.draftStartDate = start
        viewModel.draftEndDate = end
        await viewModel.applyFilter()

        let summary = try XCTUnwrap(viewModel.activeFilterSummary)
        XCTAssertTrue(summary.contains("–"))
        XCTAssertTrue(viewModel.hasActiveFilter)
    }
}
