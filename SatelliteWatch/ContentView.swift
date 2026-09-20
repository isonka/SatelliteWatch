import SwiftUI

struct ContentView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var launchesViewModel: LaunchesViewModel?
    @State private var rocketsViewModel: PaginatedListViewModel<Rocket>?
    @State private var selectedTab: AppTab = .launches

    var body: some View {
        Group {
            if let launchesViewModel, let rocketsViewModel {
                tabs(launchesViewModel: launchesViewModel, rocketsViewModel: rocketsViewModel)
                    .environment(launchesViewModel)
            } else {
                ProgressView()
            }
        }
        .onChange(of: dependencies.dataSourceMode, initial: true) { _, _ in
            let service = dependencies.spaceXService
            launchesViewModel = LaunchesViewModel(service: service)
            rocketsViewModel = PaginatedListViewModel(service: service)
            selectedTab = .launches
        }
    }

    private func tabs(
        launchesViewModel: LaunchesViewModel,
        rocketsViewModel: PaginatedListViewModel<Rocket>
    ) -> some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                LaunchesListView(
                    viewModel: launchesViewModel,
                    enablesPagination: true
                )
                .toolbar {
                    #if DEBUG
                    ToolbarItem(placement: .topBarTrailing) {
                        dataSourceMenu
                    }
                    #endif
                }
            }
            .id("launches-\(dependencies.dataSourceMode.rawValue)")
            .tabItem {
                Label("Launches", systemImage: "airplane.departure")
            }
            .tag(AppTab.launches)

            NavigationStack {
                RocketsListView(
                    viewModel: rocketsViewModel,
                    enablesPagination: true
                )
            }
            .id("rockets-\(dependencies.dataSourceMode.rawValue)")
            .tabItem {
                Label("Rockets", systemImage: "flame.fill")
            }
            .tag(AppTab.rockets)
        }
    }

    #if DEBUG
    private var dataSourceMenu: some View {
        Menu {
            ForEach(DataSourceMode.allCases) { mode in
                Button {
                    dependencies.dataSourceMode = mode
                } label: {
                    Label(mode.menuTitle, systemImage: mode.symbolName)
                    if mode == dependencies.dataSourceMode {
                        Image(systemName: "checkmark")
                    }
                }
            }

            if let origin = dependencies.dataSourceMode.baseURLDescription {
                Section("Origin") {
                    Text(origin)
                }
            }
        } label: {
            Label(
                dependencies.dataSourceMode.title,
                systemImage: dependencies.dataSourceMode.symbolName
            )
        }
        .accessibilityIdentifier("debug-data-source-menu")
        .accessibilityLabel("Data source")
    }
    #endif
}

#Preview {
    ContentView()
        .environment(AppDependencies.preview)
}
