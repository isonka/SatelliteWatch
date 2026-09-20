import SwiftUI

struct RocketsListView: View {
    private let viewModel: PaginatedListViewModel<Rocket>
    private let loadsOnAppear: Bool
    private let enablesPagination: Bool

    init(
        viewModel: PaginatedListViewModel<Rocket>,
        loadsOnAppear: Bool = false,
        enablesPagination: Bool = false
    ) {
        self.viewModel = viewModel
        self.loadsOnAppear = loadsOnAppear
        self.enablesPagination = enablesPagination
    }

    var body: some View {
        Group {
            if viewModel.isInitialLoading && viewModel.items.isEmpty {
                LoadingStateView(message: "Loading rockets…")
            } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                ErrorStateView(message: errorMessage) {
                    Task { await viewModel.retry() }
                }
            } else if viewModel.items.isEmpty {
                EmptyStateView(
                    title: "No rockets",
                    systemImage: "flame.fill",
                    description: "There are no rockets to show right now."
                )
            } else {
                listContent
            }
        }
        .navigationTitle("Rockets")
        .task(id: ObjectIdentifier(viewModel)) {
            await loadIfNeeded()
        }
    }

    private var listContent: some View {
        List {
            ForEach(viewModel.items) { rocket in
                NavigationLink(value: rocket) {
                    RocketRowView(rocket: rocket)
                }
                .onAppear {
                    guard enablesPagination,
                          viewModel.shouldLoadNextPage(currentItem: rocket)
                    else { return }
                    Task {
                        await viewModel.loadNextPageIfNeeded(currentItem: rocket)
                    }
                }
            }

            if viewModel.isLoadingMore {
                HStack(spacing: Spacing.md) {
                    ProgressView()
                    Text("Loading more…")
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColor.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .listRowSeparator(.hidden)
                .accessibilityIdentifier("rockets-loading-more")
            }

            if let errorMessage = viewModel.errorMessage, !viewModel.items.isEmpty {
                LoadMoreErrorFooter(
                    message: errorMessage,
                    messageIdentifier: "rockets-inline-error",
                    retryIdentifier: "rockets-load-more-retry"
                ) {
                    Task { await viewModel.retry() }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
        .navigationDestination(for: Rocket.self) { rocket in
            RocketDetailView(rocket: rocket)
        }
        .accessibilityIdentifier("rockets-list")
    }

    private func loadIfNeeded() async {
        guard loadsOnAppear else { return }
        guard viewModel.items.isEmpty, !viewModel.isInitialLoading else { return }
        await viewModel.loadInitial()
    }
}

#if DEBUG
#Preview("Populated") {
    NavigationStack {
        RocketsListView(
            viewModel: .preview(rockets: [MockSpaceXService.previewRocket])
        )
    }
    .environment(AppDependencies.preview)
    .environment(LaunchesViewModel.preview(launches: MockSpaceXService.previewLaunches))
}

#Preview("Populated + loading more") {
    NavigationStack {
        RocketsListView(
            viewModel: .preview(
                rockets: [MockSpaceXService.previewRocket],
                isLoadingMore: true,
                hasNextPage: true
            )
        )
    }
    .environment(AppDependencies.preview)
    .environment(LaunchesViewModel.preview(launches: MockSpaceXService.previewLaunches))
}
#endif
