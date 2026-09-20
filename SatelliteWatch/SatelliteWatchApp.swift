import SwiftUI

@main
struct SatelliteWatchApp: App {
    @State private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            ContentView(service: dependencies.spaceXService)
                .environment(dependencies)
        }
    }
}
