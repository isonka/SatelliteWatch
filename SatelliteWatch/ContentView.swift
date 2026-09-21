import SwiftUI

struct ContentView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var launchesViewModel: LaunchesViewModel
    @State private var rocketsViewModel: PaginatedListViewModel<Rocket>
    @State private var selectedTab: AppTab = .launches
    @State private var launchesPath = NavigationPath()
    @State private var rocketsPath = NavigationPath()

    init(service: any ServiceProtocol) {
        _launchesViewModel = State(initialValue: LaunchesViewModel(service: service))
        _rocketsViewModel = State(initialValue: PaginatedListViewModel(service: service))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $launchesPath) {
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
                .modifier(DetailDestinations(
                    service: dependencies.spaceXService,
                    launchesViewModel: launchesViewModel
                ))
            }
            .tabItem {
                Label("Launches", systemImage: "airplane.departure")
            }
            .tag(AppTab.launches)

            NavigationStack(path: $rocketsPath) {
                RocketsListView(
                    viewModel: rocketsViewModel,
                    enablesPagination: true
                )
                .modifier(DetailDestinations(
                    service: dependencies.spaceXService,
                    launchesViewModel: launchesViewModel
                ))
            }
            .tabItem {
                Label("Rockets", systemImage: "flame.fill")
            }
            .tag(AppTab.rockets)
        }
        .onChange(of: dependencies.dataSourceMode) { _, _ in
            let service = dependencies.spaceXService
            launchesViewModel = LaunchesViewModel(service: service)
            rocketsViewModel = PaginatedListViewModel(service: service)
            launchesPath = NavigationPath()
            rocketsPath = NavigationPath()
            selectedTab = .launches
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

private struct DetailDestinations: ViewModifier {
    let service: any ServiceProtocol
    let launchesViewModel: LaunchesViewModel

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: Launch.self) { launch in
                LaunchDetailView(launch: launch, service: service)
            }
            .navigationDestination(for: Rocket.self) { rocket in
                RocketDetailView(rocket: rocket, launchesViewModel: launchesViewModel)
            }
    }
}

#Preview {
    let dependencies = AppDependencies.preview
    ContentView(service: dependencies.spaceXService)
        .environment(dependencies)
}
