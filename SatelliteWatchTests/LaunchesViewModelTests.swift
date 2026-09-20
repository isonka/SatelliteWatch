import XCTest
@testable import SatelliteWatch

@MainActor
final class LaunchesViewModelTests: XCTestCase {
    private let calendar = Calendar.current

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Applies a filter over an already-primed response queue.
    @discardableResult
    private func applyFilter(
        on viewModel: LaunchesViewModel,
        from start: Date,
        to end: Date
    ) async -> LaunchesViewModel {
        viewModel.draftStartDate = start
        viewModel.draftEndDate = end
        await viewModel.applyFilter()
        return viewModel
    }

    // MARK: - Applying and clearing

    func testApplyFilterPassesDatesToService() async throws {
        let service = ControllableSpaceXService()
        service.enqueueLaunchResponse(.page([.fixture(id: "filtered")], page: 1))
        let viewModel = LaunchesViewModel(service: service)

        let start = day(2024, 1, 1)
        let end = day(2024, 1, 31)
        await applyFilter(on: viewModel, from: start, to: end)

        XCTAssertTrue(viewModel.hasActiveFilter)
        XCTAssertEqual(viewModel.startDate, startOfDay(start))
        XCTAssertEqual(viewModel.endDate, startOfDay(end))
        XCTAssertEqual(viewModel.launches.map(\.id), ["filtered"])

        let call = try XCTUnwrap(service.launchCalls.last)
        XCTAssertEqual(call.start, startOfDay(start))
        XCTAssertEqual(call.end, startOfDay(end))
    }

    func testClearFilterRemovesDatesAndReloads() async throws {
        let service = ControllableSpaceXService()
        service.enqueueLaunchResponse(.page([.fixture(id: "a")], page: 1))
        service.enqueueLaunchResponse(.page([.fixture(id: "b")], page: 1))
        let viewModel = LaunchesViewModel(service: service)

        await applyFilter(on: viewModel, from: day(2020, 9, 13), to: day(2023, 11, 14))
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

        viewModel.draftStartDate = day(2024, 2, 1)
        viewModel.draftEndDate = day(2024, 1, 1)
        XCTAssertFalse(viewModel.canApplyDraftFilter)

        viewModel.draftEndDate = day(2024, 3, 1)
        XCTAssertTrue(viewModel.canApplyDraftFilter)
    }

    func testSingleDayRangeIsApplicable() {
        let viewModel = LaunchesViewModel(service: ControllableSpaceXService())
        let sameDay = day(2024, 6, 1)

        viewModel.draftStartDate = sameDay
        viewModel.draftEndDate = sameDay

        XCTAssertTrue(viewModel.canApplyDraftFilter)
    }

    func testApplyFilterIgnoredWhenDraftInvalid() async {
        let service = ControllableSpaceXService()
        let viewModel = LaunchesViewModel(service: service)

        await applyFilter(on: viewModel, from: day(2025, 1, 1), to: day(2024, 1, 1))

        XCTAssertTrue(service.launchCalls.isEmpty)
        XCTAssertFalse(viewModel.hasActiveFilter)
    }

    // MARK: - Filter and pagination together

    /// The filter lives in a box captured by the fetch closure. If page 2 were
    /// to drop the dates, the list would silently mix filtered and unfiltered
    /// launches as the user scrolls.
    func testFilterDatesSurviveIntoSubsequentPages() async throws {
        let service = ControllableSpaceXService()
        service.enqueueLaunchResponse(.page([.fixture(id: "a")], page: 1, limit: 1, hasNextPage: true))
        service.enqueueLaunchResponse(.page([.fixture(id: "b")], page: 2, limit: 1, hasNextPage: false))
        let viewModel = LaunchesViewModel(service: service, pageSize: 1)

        let start = day(2024, 1, 1)
        let end = day(2024, 1, 31)
        await applyFilter(on: viewModel, from: start, to: end)
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.launches.last)

        XCTAssertEqual(viewModel.launches.map(\.id), ["a", "b"])
        XCTAssertEqual(service.launchCalls.count, 2)

        let secondPage = try XCTUnwrap(service.launchCalls.last)
        XCTAssertEqual(secondPage.page, 2)
        XCTAssertEqual(secondPage.start, startOfDay(start))
        XCTAssertEqual(secondPage.end, startOfDay(end))
    }

    /// Clearing the filter has to drop the dates for later pages too, not just
    /// for the reload it triggers.
    func testClearingFilterAlsoClearsDatesOnSubsequentPages() async throws {
        let service = ControllableSpaceXService()
        service.enqueueLaunchResponse(.page([.fixture(id: "filtered")], page: 1, limit: 1))
        service.enqueueLaunchResponse(.page([.fixture(id: "a")], page: 1, limit: 1, hasNextPage: true))
        service.enqueueLaunchResponse(.page([.fixture(id: "b")], page: 2, limit: 1, hasNextPage: false))
        let viewModel = LaunchesViewModel(service: service, pageSize: 1)

        await applyFilter(on: viewModel, from: day(2024, 1, 1), to: day(2024, 1, 31))
        await viewModel.clearFilter()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.launches.last)

        let secondPage = try XCTUnwrap(service.launchCalls.last)
        XCTAssertEqual(secondPage.page, 2)
        XCTAssertNil(secondPage.start)
        XCTAssertNil(secondPage.end)
    }

    /// Applying a filter restarts paging from page 1.
    func testApplyFilterRestartsPagingFromTheFirstPage() async {
        let service = ControllableSpaceXService()
        service.enqueueLaunchResponse(.page([.fixture(id: "a")], page: 1, limit: 1, hasNextPage: true))
        service.enqueueLaunchResponse(.page([.fixture(id: "b")], page: 2, limit: 1, hasNextPage: true))
        service.enqueueLaunchResponse(.page([.fixture(id: "c")], page: 1, limit: 1, hasNextPage: false))
        let viewModel = LaunchesViewModel(service: service, pageSize: 1)

        await viewModel.loadInitial()
        await viewModel.loadNextPageIfNeeded(currentItem: viewModel.launches.last)
        XCTAssertEqual(viewModel.launches.count, 2)

        await applyFilter(on: viewModel, from: day(2024, 1, 1), to: day(2024, 1, 31))

        XCTAssertEqual(viewModel.launches.map(\.id), ["c"])
        XCTAssertEqual(service.launchCalls.map(\.page), [1, 2, 1])
    }

    /// The de-duplication set has to be cleared along with the rows, or a
    /// launch that appeared before the filter would be swallowed after it.
    func testApplyFilterClearsDeduplicationSoRepeatedIDsStillAppear() async {
        let service = ControllableSpaceXService()
        service.enqueueLaunchResponse(.page([.fixture(id: "repeat")], page: 1))
        service.enqueueLaunchResponse(.page([.fixture(id: "repeat")], page: 1))
        let viewModel = LaunchesViewModel(service: service)

        await viewModel.loadInitial()
        await applyFilter(on: viewModel, from: day(2024, 1, 1), to: day(2024, 1, 31))

        XCTAssertEqual(viewModel.launches.map(\.id), ["repeat"])
    }

    // MARK: - Draft and summary

    func testPrepareFilterDraftUsesActiveFilterWhenPresent() async {
        let service = ControllableSpaceXService()
        service.enqueueLaunchResponse(.page([], page: 1))
        let viewModel = LaunchesViewModel(service: service)
        let start = day(2023, 5, 1)
        let end = day(2023, 5, 10)

        await applyFilter(on: viewModel, from: start, to: end)

        viewModel.draftStartDate = Date()
        viewModel.draftEndDate = Date()
        viewModel.prepareFilterDraft()

        XCTAssertEqual(viewModel.draftStartDate, startOfDay(start))
        XCTAssertEqual(viewModel.draftEndDate, startOfDay(end))
    }

    func testPrepareFilterDraftFallsBackToTrailingYearWhenNoFilter() throws {
        let viewModel = LaunchesViewModel(service: ControllableSpaceXService())

        viewModel.prepareFilterDraft()

        XCTAssertTrue(viewModel.canApplyDraftFilter)
        let expectedStart = try XCTUnwrap(
            calendar.date(byAdding: .year, value: -1, to: viewModel.draftEndDate)
        )
        XCTAssertEqual(
            calendar.dateComponents([.year, .month, .day], from: viewModel.draftStartDate),
            calendar.dateComponents([.year, .month, .day], from: expectedStart)
        )
    }

    func testActiveFilterSummaryShowsBothBoundsOfTheRange() async throws {
        let service = ControllableSpaceXService()
        service.enqueueLaunchResponse(.page([], page: 1))
        let viewModel = LaunchesViewModel(service: service)
        let start = day(2024, 1, 1)
        let end = day(2024, 1, 2)

        await applyFilter(on: viewModel, from: start, to: end)

        let summary = try XCTUnwrap(viewModel.activeFilterSummary)
        XCTAssertEqual(
            summary,
            "\(DateFormatting.dayOnly(startOfDay(start))) – \(DateFormatting.dayOnly(startOfDay(end)))"
        )
    }

    func testNoSummaryWithoutAnActiveFilter() {
        let viewModel = LaunchesViewModel(service: ControllableSpaceXService())

        XCTAssertNil(viewModel.activeFilterSummary)
        XCTAssertFalse(viewModel.hasActiveFilter)
    }
}
