import XCTest
@testable import SatelliteWatch

final class DataSourceModeTests: XCTestCase {
    func testResolvePrefersSampleOverMirror() {
        let mode = DataSourceMode.resolve(
            from: ["-sampleData", "-mirrorData"],
            fallback: .live
        )
        XCTAssertEqual(mode, .sample)
    }

    func testResolveMirrorArgument() {
        let mode = DataSourceMode.resolve(from: ["-mirrorData"], fallback: .live)
        XCTAssertEqual(mode, .mirror)
    }

    func testResolveFallsBackWhenNoArguments() {
        XCTAssertEqual(DataSourceMode.resolve(from: [], fallback: .mirror), .mirror)
        XCTAssertEqual(DataSourceMode.resolve(from: ["-other"], fallback: .live), .live)
    }

    func testTitlesAndSymbols() {
        XCTAssertEqual(DataSourceMode.live.title, "SpaceX API")
        XCTAssertEqual(DataSourceMode.mirror.title, "Launch Library 2")
        XCTAssertEqual(DataSourceMode.sample.title, "Sample data")
        XCTAssertEqual(DataSourceMode.live.symbolName, "network")
        XCTAssertEqual(DataSourceMode.mirror.symbolName, "arrow.triangle.branch")
        XCTAssertEqual(DataSourceMode.sample.symbolName, "shippingbox")
    }

    func testSampleHasNoHost() {
        XCTAssertNil(DataSourceMode.sample.host)
        XCTAssertEqual(DataSourceMode.sample.menuTitle, "Sample data")
    }
}
