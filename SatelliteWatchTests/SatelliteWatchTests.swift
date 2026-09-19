import Testing
@testable import SatelliteWatch

@MainActor
struct SatelliteWatchTests {
    @Test func liveDependenciesUseAPIClient() {
        let service = AppDependencies.live.spaceXService
        #expect(service is SpaceXAPIClient)
    }
}
