import SwiftUI

struct RocketsListView: View {
    @State private var viewModel: RocketsViewModel
    private let loadsOnAppear: Bool
    private let enablesPagination: Bool

    init(service: any SpaceXServiceProtocol) {
        _viewModel = State(initialValue: RocketsViewModel(service: service))
        loadsOnAppear = true
        enablesPagination = true
    }

    init(
        viewModel: RocketsViewModel,
        loadsOnAppear: Bool = false,
        enablesPagination: Bool = false
    ) {
        _viewModel = State(initialValue: viewModel)
        self.loadsOnAppear = loadsOnAppear
        self.enablesPagination = enablesPagination
    }

    var body: some View {
        Group {
            if viewModel.isInitialLoading && viewModel.rockets.isEmpty {
                LoadingStateView(message: "Loading rockets…")
            } else if let errorMessage = viewModel.errorMessage, viewModel.rockets.isEmpty {
                ErrorStateView(message: errorMessage) {
                    Task { await viewModel.retry() }
                }
            } else if viewModel.rockets.isEmpty {
                EmptyStateView(
                    title: "No rockets",
                    systemImage: "airplane",
                    description: "There are no rockets to show right now."
                )
            } else {
                listContent
            }
        }
        .navigationTitle("Rockets")
        .task {
            guard loadsOnAppear else { return }
            guard viewModel.rockets.isEmpty, !viewModel.isInitialLoading else { return }
            await viewModel.loadInitial()
        }
    }

    private var listContent: some View {
        List {
            ForEach(viewModel.rockets) { rocket in
                NavigationLink(value: rocket) {
                    RocketRowView(rocket: rocket)
                }
                .onAppear {
                    guard enablesPagination else { return }
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
            }

            if let errorMessage = viewModel.errorMessage, !viewModel.rockets.isEmpty {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Spacing.xs)
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
}

#if DEBUG
#Preview("Populated") {
    NavigationStack {
        RocketsListView(
            viewModel: .preview(rockets: [MockSpaceXService.previewRocket])
        )
    }
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
}
#endif
