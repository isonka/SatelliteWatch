import Foundation
import Observation

@Observable
@MainActor
class PaginatedListViewModel<Item: Identifiable & Decodable & Sendable> where Item.ID: Hashable {
    private(set) var items: [Item] = []
    private(set) var isInitialLoading = false
    private(set) var isLoadingMore = false
    private(set) var isRefreshing = false
    private(set) var errorMessage: String?
    private(set) var hasNextPage = true

    private let pageSize: Int
    private let fetchPage: (Int, Int) async throws -> PaginatedResponse<Item>
    private var currentPage = 0
    private var loadTask: Task<Void, Never>?
    private var requestGeneration = 0
    private var knownIDs = Set<Item.ID>()

    init(
        pageSize: Int = 20,
        fetchPage: @escaping (Int, Int) async throws -> PaginatedResponse<Item>
    ) {
        self.pageSize = pageSize
        self.fetchPage = fetchPage
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
        if items.isEmpty {
            await loadInitial()
        } else if let last = items.last {
            await loadNextPageIfNeeded(currentItem: last)
        }
    }

    func loadNextPageIfNeeded(currentItem: Item?) async {
        guard let currentItem else { return }
        guard let index = items.firstIndex(where: { $0.id == currentItem.id }) else { return }
        let thresholdIndex = max(items.count - 5, 0)
        guard index >= thresholdIndex else { return }
        guard hasNextPage else { return }
        guard !isInitialLoading, !isRefreshing else { return }

        await load(page: currentPage + 1, mode: .append)
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
            items = []
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
            let response = try await fetchPage(page, pageSize)

            guard !Task.isCancelled, generation == requestGeneration else { return }

            switch mode {
            case .replace:
                knownIDs = Set(response.docs.map(\.id))
                items = response.docs
            case .append:
                let fresh = response.docs.filter { knownIDs.insert($0.id).inserted }
                items.append(contentsOf: fresh)
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

extension PaginatedListViewModel where Item == Rocket {
    convenience init(service: any SpaceXServiceProtocol, pageSize: Int = 20) {
        self.init(pageSize: pageSize) { page, limit in
            try await service.fetchRockets(page: page, limit: limit)
        }
    }
}

#if DEBUG
extension PaginatedListViewModel {
    func applyPreviewState(
        items: [Item] = [],
        isInitialLoading: Bool = false,
        isLoadingMore: Bool = false,
        errorMessage: String? = nil,
        hasNextPage: Bool = false
    ) {
        self.items = items
        self.isInitialLoading = isInitialLoading
        self.isLoadingMore = isLoadingMore
        self.errorMessage = errorMessage
        self.hasNextPage = hasNextPage
        knownIDs = Set(items.map(\.id))
        currentPage = items.isEmpty ? 0 : 1
    }
}

extension PaginatedListViewModel where Item == Rocket {
    static func preview(
        rockets: [Rocket] = [],
        isInitialLoading: Bool = false,
        isLoadingMore: Bool = false,
        errorMessage: String? = nil,
        hasNextPage: Bool = false
    ) -> PaginatedListViewModel<Rocket> {
        let viewModel = PaginatedListViewModel(service: MockSpaceXService())
        viewModel.applyPreviewState(
            items: rockets,
            isInitialLoading: isInitialLoading,
            isLoadingMore: isLoadingMore,
            errorMessage: errorMessage,
            hasNextPage: hasNextPage
        )
        return viewModel
    }
}
#endif
