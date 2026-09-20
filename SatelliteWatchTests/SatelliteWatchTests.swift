import XCTest
@testable import SatelliteWatch

@MainActor
final class SatelliteWatchTests: XCTestCase {
    func testLiveDependenciesUseAPIClient() {
        let dependencies = AppDependencies(dataSourceMode: .live)
        XCTAssertTrue(dependencies.spaceXService is SpaceXAPIClient)
    }

    func testSampleDependenciesUseMockService() {
        let dependencies = AppDependencies(dataSourceMode: .sample)
        XCTAssertTrue(dependencies.spaceXService is MockSpaceXService)
    }

    func testSwitchingModeReplacesService() {
        let dependencies = AppDependencies(dataSourceMode: .live)
        dependencies.dataSourceMode = .sample
        XCTAssertTrue(dependencies.spaceXService is MockSpaceXService)
        dependencies.dataSourceMode = .live
        XCTAssertTrue(dependencies.spaceXService is SpaceXAPIClient)
    }

    func testSampleDataLaunchArgumentResolvesToSampleMode() {
        XCTAssertEqual(DataSourceMode.resolve(from: ["-sampleData"]), .sample)
    }

    func testMissingSampleDataLaunchArgumentResolvesToLive() {
        XCTAssertEqual(DataSourceMode.resolve(from: ["-foo"]), .live)
    }
}
