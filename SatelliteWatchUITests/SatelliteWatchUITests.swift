import XCTest

@MainActor
final class SatelliteWatchUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-sampleData"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testLaunchesTabShowsSampleList() {
        XCTAssertTrue(app.tabBars.buttons["Launches"].waitForExistence(timeout: 5))
        XCTAssertTrue(element(id: "launch-row-launch-1").waitForExistence(timeout: 8))
        XCTAssertTrue(element(id: "launches-list").exists)
    }

    func testRocketsTabShowsSampleList() {
        let rocketsTab = app.tabBars.buttons["Rockets"]
        XCTAssertTrue(rocketsTab.waitForExistence(timeout: 5))
        rocketsTab.tap()

        XCTAssertTrue(element(id: "rocket-row-falcon9").waitForExistence(timeout: 8))
        XCTAssertTrue(element(id: "rockets-list").exists)
    }

    func testDateFilterApplyAndClear() {
        XCTAssertTrue(element(id: "launch-row-launch-1").waitForExistence(timeout: 8))

        element(id: "launches-filter-button").tap()
        XCTAssertTrue(element(id: "filter-apply").waitForExistence(timeout: 5))
        element(id: "filter-apply").tap()

        let filteredEmpty = element(id: "empty-state").waitForExistence(timeout: 8)
        let filteredSummary = element(id: "active-filter-summary").waitForExistence(timeout: 2)
        XCTAssertTrue(filteredEmpty || filteredSummary)

        element(id: "launches-filter-button").tap()
        XCTAssertTrue(element(id: "filter-clear").waitForExistence(timeout: 5))
        element(id: "filter-clear").tap()

        XCTAssertTrue(element(id: "launch-row-launch-1").waitForExistence(timeout: 8))
    }

    func testLaunchDetailNavigatesToRocketDetail() {
        XCTAssertTrue(element(id: "launch-row-launch-1").waitForExistence(timeout: 8))
        element(id: "launch-row-launch-1").tap()

        XCTAssertTrue(element(id: "launch-detail-launch-1").waitForExistence(timeout: 8))
        XCTAssertTrue(element(id: "rocket-card-falcon9").waitForExistence(timeout: 8))
        element(id: "rocket-card-falcon9").tap()

        XCTAssertTrue(element(id: "rocket-detail-falcon9").waitForExistence(timeout: 8))
    }

    func testRocketDetailShowsLaunchesFromLoadedList() {
        XCTAssertTrue(element(id: "launch-row-launch-1").waitForExistence(timeout: 8))

        let rocketsTab = app.tabBars.buttons["Rockets"]
        XCTAssertTrue(rocketsTab.waitForExistence(timeout: 5))
        rocketsTab.tap()

        XCTAssertTrue(element(id: "rocket-row-falcon9").waitForExistence(timeout: 8))
        element(id: "rocket-row-falcon9").tap()

        XCTAssertTrue(element(id: "rocket-detail-falcon9").waitForExistence(timeout: 8))
        XCTAssertTrue(element(id: "rocket-launch-row-launch-1").waitForExistence(timeout: 8))
        XCTAssertTrue(element(id: "rocket-launch-row-launch-2").waitForExistence(timeout: 8))
    }

    private func element(id: String) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }
}
