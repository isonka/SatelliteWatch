import Foundation
import Observation

@Observable
@MainActor
final class LaunchesViewModel {
    private(set) var launches: [Launch] = []
    private(set) var isInitialLoading = false
    private(set) var isLoadingMore = false
    private(set) var isRefreshing = false
    private(set) var errorMessage: String?
    private(set) var hasNextPage = true
    private(set) var startDate: Date?
    private(set) var endDate: Date?

    var draftStartDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    var draftEndDate: Date = Date()

    private let service: any SpaceXServiceProtocol
    private let pageSize: Int
    private var currentPage = 0
    private var loadTask: Task<Void, Never>?
    private var requestGeneration = 0
    private var knownIDs = Set<String>()

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
        self.service = service
        self.pageSize = pageSize
    }

    func loadInitial() async {
        await load(page: 1, mode: .replace)
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        errorMessage = nil
        await load(page: 1, mode: .replace)
    }

    func retry() async {
        if launches.isEmpty {
            await loadInitial()
        } else if let last = launches.last {
            await loadNextPageIfNeeded(currentItem: last)
        }
    }

    func loadNextPageIfNeeded(currentItem: Launch?) async {
        guard let currentItem else { return }
        guard let index = launches.firstIndex(where: { $0.id == currentItem.id }) else { return }
        let thresholdIndex = max(launches.count - 5, 0)
        guard index >= thresholdIndex else { return }
        guard hasNextPage else { return }
        guard !isInitialLoading, !isRefreshing else { return }

        await load(page: currentPage + 1, mode: .append)
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

    private enum LoadMode {
        case replace
        case append
    }

    private func load(page: Int, mode: LoadMode) async {
        switch mode {
        case .append:
            guard loadTask == nil else { return }
        case .replace:
            loadTask?.cancel()
        }

        requestGeneration += 1
        let generation = requestGeneration

        switch mode {
        case .replace:
            currentPage = 0
            hasNextPage = true
            knownIDs.removeAll()
            launches = []
            isLoadingMore = false
            isInitialLoading = true
            errorMessage = nil
        case .append:
            isLoadingMore = true
        }

        loadTask = Task {
            await performFetch(page: page, mode: mode, generation: generation)
        }
        await loadTask?.value

        if generation == requestGeneration {
            loadTask = nil
        }
    }

    private func performFetch(page: Int, mode: LoadMode, generation: Int) async {
        defer {
            if generation == requestGeneration {
                isInitialLoading = false
                isLoadingMore = false
            }
        }

        do {
            let response = try await service.fetchLaunches(
                page: page,
                limit: pageSize,
                startDate: startDate,
                endDate: endDate
            )

            guard !Task.isCancelled, generation == requestGeneration else { return }

            switch mode {
            case .replace:
                knownIDs = Set(response.docs.map(\.id))
                launches = response.docs
            case .append:
                let fresh = response.docs.filter { knownIDs.insert($0.id).inserted }
                launches.append(contentsOf: fresh)
            }

            currentPage = response.page
            hasNextPage = response.hasNextPage
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, generation == requestGeneration else { return }
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
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
        viewModel.launches = launches
        viewModel.isInitialLoading = isInitialLoading
        viewModel.isLoadingMore = isLoadingMore
        viewModel.errorMessage = errorMessage
        viewModel.hasNextPage = hasNextPage
        viewModel.startDate = startDate
        viewModel.endDate = endDate
        viewModel.knownIDs = Set(launches.map(\.id))
        viewModel.currentPage = launches.isEmpty ? 0 : 1
        return viewModel
    }
}
#endif
