import XCTest
@testable import SatelliteWatch

final class LaunchDateRangeEncoderTests: XCTestCase {
    private var calendar: Calendar!
    private var timeZone: TimeZone!

    override func setUp() {
        super.setUp()
        timeZone = TimeZone(secondsFromGMT: 5 * 3600)!
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
    }

    func testQueryBoundsStartIsLocalStartOfDayInUTC() {
        let start = date(year: 2024, month: 3, day: 10)
        let bounds = LaunchDateRangeEncoder.queryBounds(
            start: start,
            end: nil,
            calendar: calendar,
            timeZone: timeZone
        )

        XCTAssertEqual(bounds.startUTC, "2024-03-09T19:00:00.000Z")
        XCTAssertNil(bounds.endUTC)
    }

    func testQueryBoundsEndIsInclusiveLocalDayAsUTCLte() {
        let end = date(year: 2024, month: 3, day: 10)
        let bounds = LaunchDateRangeEncoder.queryBounds(
            start: nil,
            end: end,
            calendar: calendar,
            timeZone: timeZone
        )

        XCTAssertNil(bounds.startUTC)
        XCTAssertEqual(bounds.endUTC, "2024-03-10T18:59:59.999Z")
    }

    func testQueryBoundsBothNil() {
        let bounds = LaunchDateRangeEncoder.queryBounds(
            start: nil,
            end: nil,
            calendar: calendar,
            timeZone: timeZone
        )
        XCTAssertNil(bounds.startUTC)
        XCTAssertNil(bounds.endUTC)
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        minute: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }
}
