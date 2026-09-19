import Foundation
import Observation

@Observable
@MainActor
final class RocketsViewModel {
    private(set) var rockets: [Rocket] = []
    private(set) var isInitialLoading = false
    private(set) var isLoadingMore = false
    private(set) var isRefreshing = false
    private(set) var errorMessage: String?
    private(set) var hasNextPage = true

    private let service: any SpaceXServiceProtocol
    private let pageSize: Int
    private var currentPage = 0
    private var loadTask: Task<Void, Never>?
    private var requestGeneration = 0
    private var knownIDs = Set<String>()

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
        if rockets.isEmpty {
            await loadInitial()
        } else if let last = rockets.last {
            await loadNextPageIfNeeded(currentItem: last)
        }
    }

    func loadNextPageIfNeeded(currentItem: Rocket?) async {
        guard let currentItem else { return }
        guard let index = rockets.firstIndex(where: { $0.id == currentItem.id }) else { return }
        let thresholdIndex = max(rockets.count - 5, 0)
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
            rockets = []
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
            let response = try await service.fetchRockets(page: page, limit: pageSize)

            guard !Task.isCancelled, generation == requestGeneration else { return }

            switch mode {
            case .replace:
                knownIDs = Set(response.docs.map(\.id))
                rockets = response.docs
            case .append:
                let fresh = response.docs.filter { knownIDs.insert($0.id).inserted }
                rockets.append(contentsOf: fresh)
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
extension RocketsViewModel {
    static func preview(
        rockets: [Rocket] = [],
        isInitialLoading: Bool = false,
        isLoadingMore: Bool = false,
        errorMessage: String? = nil,
        hasNextPage: Bool = false
    ) -> RocketsViewModel {
        let viewModel = RocketsViewModel(service: MockSpaceXService())
        viewModel.rockets = rockets
        viewModel.isInitialLoading = isInitialLoading
        viewModel.isLoadingMore = isLoadingMore
        viewModel.errorMessage = errorMessage
        viewModel.hasNextPage = hasNextPage
        viewModel.knownIDs = Set(rockets.map(\.id))
        viewModel.currentPage = rockets.isEmpty ? 0 : 1
        return viewModel
    }
}
#endif
