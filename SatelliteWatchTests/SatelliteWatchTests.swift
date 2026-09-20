import Testing
@testable import SatelliteWatch

@MainActor
struct SatelliteWatchTests {
    @Test func liveDependenciesUseAPIClient() {
        let dependencies = AppDependencies(dataSourceMode: .live)
        #expect(dependencies.spaceXService is SpaceXAPIClient)
    }

    @Test func sampleDependenciesUseMockService() {
        let dependencies = AppDependencies(dataSourceMode: .sample)
        #expect(dependencies.spaceXService is MockSpaceXService)
    }

    @Test func switchingModeReplacesService() {
        let dependencies = AppDependencies(dataSourceMode: .live)
        dependencies.dataSourceMode = .sample
        #expect(dependencies.spaceXService is MockSpaceXService)
        dependencies.dataSourceMode = .live
        #expect(dependencies.spaceXService is SpaceXAPIClient)
    }

    @Test func sampleDataLaunchArgumentResolvesToSampleMode() {
        #expect(DataSourceMode.resolve(from: ["-sampleData"]) == .sample)
    }

    @Test func missingSampleDataLaunchArgumentResolvesToLive() {
        #expect(DataSourceMode.resolve(from: ["-foo"]) == .live)
    }
}
