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

    func testMissingLaunchArgumentResolvesToMirrorByDefault() {
        XCTAssertEqual(DataSourceMode.resolve(from: ["-foo"]), .mirror)
    }

    func testResolveHonorsExplicitLiveFallback() {
        XCTAssertEqual(
            DataSourceMode.resolve(from: ["-foo"], fallback: .live),
            .live
        )
    }

    func testMirrorDependenciesUseLaunchLibraryClient() {
        let dependencies = AppDependencies(dataSourceMode: .mirror)
        XCTAssertTrue(dependencies.spaceXService is LaunchLibraryAPIClient)
    }

    func testRateLimitErrorIsSourceAgnostic() {
        XCTAssertEqual(
            SpaceXAPIError.httpStatus(429).errorDescription,
            "Too many requests. Wait and try again."
        )
    }

    func testArchivedOriginErrorOmitsDebugToolbar() {
        let message = SpaceXAPIError.httpStatus(525).errorDescription ?? ""
        XCTAssertTrue(message.contains("archived"))
        XCTAssertFalse(message.contains("toolbar"))
        XCTAssertFalse(message.contains("Debug"))
    }
}
