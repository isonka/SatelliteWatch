import SwiftUI

struct ContentView: View {
    @Bindable var dependencies: AppDependencies

    var body: some View {
        TabView {
            NavigationStack {
                LaunchesListView(service: dependencies.spaceXService)
                    .id(dependencies.dataSourceMode)
                    .toolbar {
                        #if DEBUG
                        ToolbarItem(placement: .topBarTrailing) {
                            dataSourceMenu
                        }
                        #endif
                    }
            }
            .tabItem {
                Label("Launches", systemImage: "airplane.departure")
            }

            NavigationStack {
                RocketsListView(service: dependencies.spaceXService)
                    .id(dependencies.dataSourceMode)
            }
            .tabItem {
                Label("Rockets", systemImage: "airplane")
            }
        }
    }

    #if DEBUG
    private var dataSourceMenu: some View {
        Menu {
            Picker("Data source", selection: $dependencies.dataSourceMode) {
                ForEach(DataSourceMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
        } label: {
            Label(
                dependencies.dataSourceMode.title,
                systemImage: dependencies.isUsingSampleData ? "shippingbox" : "network"
            )
        }
        .accessibilityIdentifier("debug-data-source-menu")
        .accessibilityLabel("Data source")
    }
    #endif
}

#Preview {
    ContentView(dependencies: .preview)
}
