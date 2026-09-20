import XCTest

@MainActor
final class SatelliteWatchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchesTabShowsSampleList() {
        let app = launchApp()
        XCTAssertTrue(app.tabBars.buttons["Launches"].waitForExistence(timeout: 5))
        XCTAssertTrue(element(app, id: "launch-row-launch-1").waitForExistence(timeout: 8))
        XCTAssertTrue(element(app, id: "launches-list").exists)
    }

    func testRocketsTabShowsSampleList() {
        let app = launchApp()
        let rocketsTab = app.tabBars.buttons["Rockets"]
        XCTAssertTrue(rocketsTab.waitForExistence(timeout: 5))
        rocketsTab.tap()

        XCTAssertTrue(element(app, id: "rocket-row-falcon9").waitForExistence(timeout: 8))
        XCTAssertTrue(element(app, id: "rockets-list").exists)
    }

    func testDateFilterApplyAndClear() {
        let app = launchApp()
        XCTAssertTrue(element(app, id: "launch-row-launch-1").waitForExistence(timeout: 8))

        element(app, id: "launches-filter-button").tap()
        XCTAssertTrue(element(app, id: "filter-apply").waitForExistence(timeout: 5))
        element(app, id: "filter-apply").tap()

        let filteredEmpty = element(app, id: "empty-state").waitForExistence(timeout: 8)
        let filteredSummary = element(app, id: "active-filter-summary").waitForExistence(timeout: 2)
        XCTAssertTrue(filteredEmpty || filteredSummary)

        element(app, id: "launches-filter-button").tap()
        XCTAssertTrue(element(app, id: "filter-clear").waitForExistence(timeout: 5))
        element(app, id: "filter-clear").tap()

        XCTAssertTrue(element(app, id: "launch-row-launch-1").waitForExistence(timeout: 8))
    }

    func testLaunchDetailNavigatesToRocketDetail() {
        let app = launchApp()
        XCTAssertTrue(element(app, id: "launch-row-launch-1").waitForExistence(timeout: 8))
        element(app, id: "launch-row-launch-1").tap()

        XCTAssertTrue(element(app, id: "launch-detail-launch-1").waitForExistence(timeout: 8))
        XCTAssertTrue(element(app, id: "rocket-card-falcon9").waitForExistence(timeout: 8))
        element(app, id: "rocket-card-falcon9").tap()

        XCTAssertTrue(element(app, id: "rocket-detail-falcon9").waitForExistence(timeout: 8))
    }

    func testRocketDetailShowsLaunchesFromLoadedList() {
        let app = launchApp()
        XCTAssertTrue(element(app, id: "launch-row-launch-1").waitForExistence(timeout: 8))

        let rocketsTab = app.tabBars.buttons["Rockets"]
        XCTAssertTrue(rocketsTab.waitForExistence(timeout: 5))
        rocketsTab.tap()

        XCTAssertTrue(element(app, id: "rocket-row-falcon9").waitForExistence(timeout: 8))
        element(app, id: "rocket-row-falcon9").tap()

        XCTAssertTrue(element(app, id: "rocket-detail-falcon9").waitForExistence(timeout: 8))
        XCTAssertTrue(element(app, id: "rocket-launch-row-launch-1").waitForExistence(timeout: 8))
        XCTAssertTrue(element(app, id: "rocket-launch-row-launch-2").waitForExistence(timeout: 8))
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-sampleData"]
        app.launch()
        return app
    }

    private func element(_ app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }
}
