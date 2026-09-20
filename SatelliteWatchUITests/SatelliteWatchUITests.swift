import XCTest

final class SatelliteWatchUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-sampleData"] // matches DataSourceMode.sampleDataLaunchArgument
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testLaunchesTabShowsSampleList() {
        XCTAssertTrue(app.tabBars.buttons["Launches"].waitForExistence(timeout: 5))
        XCTAssertTrue(element(id: "launch-row-launch-1").waitForExistence(timeout: 8))
        XCTAssertTrue(element(id: "launches-list").exists)
    }

    @MainActor
    func testRocketsTabShowsSampleList() {
        let rocketsTab = app.tabBars.buttons["Rockets"]
        XCTAssertTrue(rocketsTab.waitForExistence(timeout: 5))
        rocketsTab.tap()

        XCTAssertTrue(element(id: "rocket-row-falcon9").waitForExistence(timeout: 8))
        XCTAssertTrue(element(id: "rockets-list").exists)
    }

    private func element(id: String) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }
}
