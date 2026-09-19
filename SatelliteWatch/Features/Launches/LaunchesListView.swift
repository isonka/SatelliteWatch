import SwiftUI

struct LaunchesListView: View {
    @State private var viewModel: LaunchesViewModel
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
                    title: "No launches",
                    systemImage: "airplane.departure",
                    description: "There are no launches to show right now."
                )
            } else {
                listContent
            }
        }
        .navigationTitle("Launches")
        .task {
            guard loadsOnAppear else { return }
            guard viewModel.launches.isEmpty, !viewModel.isInitialLoading else { return }
            await viewModel.loadInitial()
        }
    }

    private var listContent: some View {
        List {
            ForEach(viewModel.launches) { launch in
                LaunchRowView(launch: launch)
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
#endif
