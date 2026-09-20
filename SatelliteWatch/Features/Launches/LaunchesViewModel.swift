import Foundation
import Observation

@Observable
@MainActor
final class LaunchesViewModel: PaginatedListViewModel<Launch> {
    private(set) var startDate: Date? {
        didSet { filterBox.startDate = startDate }
    }

    private(set) var endDate: Date? {
        didSet { filterBox.endDate = endDate }
    }

    var draftStartDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    var draftEndDate: Date = Date()

    private let filterBox: FilterBox

    var launches: [Launch] { items }

    var hasActiveFilter: Bool {
        startDate != nil || endDate != nil
    }

    var activeFilterSummary: String? {
        switch (startDate, endDate) {
        case let (start?, end?):
            return "\(DateFormatting.dayOnly(start)) – \(DateFormatting.dayOnly(end))"
        case let (start?, nil):
            return "From \(DateFormatting.dayOnly(start))"
        case let (nil, end?):
            return "Until \(DateFormatting.dayOnly(end))"
        case (nil, nil):
            return nil
        }
    }

    var canApplyDraftFilter: Bool {
        Calendar.current.startOfDay(for: draftStartDate)
            <= Calendar.current.startOfDay(for: draftEndDate)
    }

    init(service: any SpaceXServiceProtocol, pageSize: Int = 20) {
        let filterBox = FilterBox()
        self.filterBox = filterBox
        super.init(pageSize: pageSize) { page, limit in
            try await service.fetchLaunches(
                page: page,
                limit: limit,
                startDate: filterBox.startDate,
                endDate: filterBox.endDate
            )
        }
    }

    func prepareFilterDraft() {
        draftStartDate = startDate
            ?? (Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date())
        draftEndDate = endDate ?? Date()
    }

    func applyFilter() async {
        guard canApplyDraftFilter else { return }
        startDate = Calendar.current.startOfDay(for: draftStartDate)
        endDate = Calendar.current.startOfDay(for: draftEndDate)
        await loadInitial()
    }

    func clearFilter() async {
        startDate = nil
        endDate = nil
        prepareFilterDraft()
        await loadInitial()
    }
}

private final class FilterBox: @unchecked Sendable {
    var startDate: Date?
    var endDate: Date?
}

#if DEBUG
extension LaunchesViewModel {
    static func preview(
        launches: [Launch] = [],
        isInitialLoading: Bool = false,
        isLoadingMore: Bool = false,
        errorMessage: String? = nil,
        hasNextPage: Bool = false,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> LaunchesViewModel {
        let viewModel = LaunchesViewModel(service: MockSpaceXService())
        viewModel.startDate = startDate
        viewModel.endDate = endDate
        viewModel.applyPreviewState(
            items: launches,
            isInitialLoading: isInitialLoading,
            isLoadingMore: isLoadingMore,
            errorMessage: errorMessage,
            hasNextPage: hasNextPage
        )
        return viewModel
    }
}
#endif
