import SwiftUI

struct LaunchesListView: View {
    @State private var viewModel: LaunchesViewModel
    @State private var showingFilter = false
    private let loadsOnAppear: Bool
    private let enablesPagination: Bool

    init(service: any SpaceXServiceProtocol) {
        _viewModel = State(initialValue: LaunchesViewModel(service: service))
        loadsOnAppear = true
        enablesPagination = true
    }

    init(
        viewModel: LaunchesViewModel,
        loadsOnAppear: Bool = false,
        enablesPagination: Bool = false
    ) {
        _viewModel = State(initialValue: viewModel)
        self.loadsOnAppear = loadsOnAppear
        self.enablesPagination = enablesPagination
    }

    var body: some View {
        Group {
            if viewModel.isInitialLoading && viewModel.launches.isEmpty {
                LoadingStateView(message: "Loading launches…")
            } else if let errorMessage = viewModel.errorMessage, viewModel.launches.isEmpty {
                ErrorStateView(message: errorMessage) {
                    Task { await viewModel.retry() }
                }
            } else if viewModel.launches.isEmpty {
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
        .task {
            guard loadsOnAppear else { return }
            guard viewModel.launches.isEmpty, !viewModel.isInitialLoading else { return }
            await viewModel.loadInitial()
        }
    }

    private var listContent: some View {
        List {
            ForEach(viewModel.launches) { launch in
                NavigationLink(value: launch) {
                    LaunchRowView(launch: launch)
                }
                .onAppear {
                    guard enablesPagination else { return }
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

            if let errorMessage = viewModel.errorMessage, !viewModel.launches.isEmpty {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Spacing.xs)
                    .accessibilityIdentifier("launches-inline-error")
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
        .navigationDestination(for: Launch.self) { launch in
            LaunchDetailView(launch: launch)
        }
    }
}

#if DEBUG
#Preview("Populated") {
    NavigationStack {
        LaunchesListView(
            viewModel: .preview(launches: MockSpaceXService.previewLaunches)
        )
    }
}

#Preview("Populated + loading more") {
    NavigationStack {
        LaunchesListView(
            viewModel: .preview(
                launches: MockSpaceXService.previewLaunches,
                isLoadingMore: true,
                hasNextPage: true
            )
        )
    }
}

#Preview("Populated + inline error") {
    NavigationStack {
        LaunchesListView(
            viewModel: .preview(
                launches: MockSpaceXService.previewLaunches,
                errorMessage: "Could not load the next page.",
                hasNextPage: true
            )
        )
    }
}

#Preview("Filtered empty") {
    NavigationStack {
        LaunchesListView(
            viewModel: .preview(
                startDate: Date(timeIntervalSince1970: 1_600_000_000),
                endDate: Date(timeIntervalSince1970: 1_610_000_000)
            )
        )
    }
}
#endif
