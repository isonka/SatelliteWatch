import SwiftUI

struct LaunchesListView: View {
    @State private var showingFilter = false
    private let viewModel: LaunchesViewModel
    private let loadsOnAppear: Bool
    private let enablesPagination: Bool

    init(
        viewModel: LaunchesViewModel,
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
                LoadingStateView(message: "Loading launches…")
            } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                ErrorStateView(message: errorMessage) {
                    Task { await viewModel.retry() }
                }
            } else if viewModel.items.isEmpty {
                EmptyStateView(
                    title: viewModel.hasActiveFilter ? "No launches in range" : "No launches",
                    systemImage: "airplane.departure",
                    description: viewModel.hasActiveFilter
                        ? "Try a wider date range or clear the filter."
                        : "There are no launches to show right now."
                )
            } else {
                listContent
            }
        }
        .navigationTitle("Launches")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.prepareFilterDraft()
                    showingFilter = true
                } label: {
                    Image(
                        systemName: viewModel.hasActiveFilter
                            ? "line.3.horizontal.decrease.circle.fill"
                            : "line.3.horizontal.decrease.circle"
                    )
                }
                .accessibilityLabel("Filter launches")
                .accessibilityIdentifier("launches-filter-button")
            }
        }
        .safeAreaInset(edge: .top) {
            if let summary = viewModel.activeFilterSummary {
                Text("Filtered: \(summary)")
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs)
                    .background(.bar)
                    .accessibilityIdentifier("active-filter-summary")
            }
        }
        .sheet(isPresented: $showingFilter) {
            LaunchDateFilterView(viewModel: viewModel)
        }
        .task(id: ObjectIdentifier(viewModel)) {
            await loadIfNeeded()
        }
        .onAppear {
            Task { await loadIfNeeded() }
        }
    }

    private var listContent: some View {
        List {
            ForEach(viewModel.items) { launch in
                NavigationLink(value: launch) {
                    LaunchRowView(launch: launch)
                }
                .onAppear {
                    guard enablesPagination,
                          viewModel.shouldLoadNextPage(currentItem: launch)
                    else { return }
                    Task {
                        await viewModel.loadNextPageIfNeeded(currentItem: launch)
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
                .accessibilityIdentifier("launches-loading-more")
            }

            if let errorMessage = viewModel.errorMessage, !viewModel.items.isEmpty {
                LoadMoreErrorFooter(
                    message: errorMessage,
                    messageIdentifier: "launches-inline-error",
                    retryIdentifier: "launches-load-more-retry"
                ) {
                    Task { await viewModel.retry() }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
        .navigationDestination(for: Launch.self) { launch in
            LaunchDetailView(launch: launch)
        }
        .accessibilityIdentifier("launches-list")
    }

    private func loadIfNeeded() async {
        guard loadsOnAppear else { return }
        guard viewModel.items.isEmpty, !viewModel.isInitialLoading else { return }
        await viewModel.loadInitial()
    }
}

#if DEBUG
#Preview("Populated") {
    let viewModel = LaunchesViewModel.preview(launches: MockSpaceXService.previewLaunches)
    return NavigationStack {
        LaunchesListView(viewModel: viewModel)
    }
    .environment(AppDependencies.preview)
    .environment(viewModel)
}

#Preview("Populated + loading more") {
    let viewModel = LaunchesViewModel.preview(
        launches: MockSpaceXService.previewLaunches,
        isLoadingMore: true,
        hasNextPage: true
    )
    return NavigationStack {
        LaunchesListView(viewModel: viewModel)
    }
    .environment(AppDependencies.preview)
    .environment(viewModel)
}

#Preview("Populated + inline error") {
    let viewModel = LaunchesViewModel.preview(
        launches: MockSpaceXService.previewLaunches,
        errorMessage: "Could not load the next page.",
        hasNextPage: true
    )
    return NavigationStack {
        LaunchesListView(viewModel: viewModel)
    }
    .environment(AppDependencies.preview)
    .environment(viewModel)
}

#Preview("Filtered empty") {
    let viewModel = LaunchesViewModel.preview(
        startDate: Date(timeIntervalSince1970: 1_600_000_000),
        endDate: Date(timeIntervalSince1970: 1_610_000_000)
    )
    return NavigationStack {
        LaunchesListView(viewModel: viewModel)
    }
    .environment(AppDependencies.preview)
    .environment(viewModel)
}
#endif
