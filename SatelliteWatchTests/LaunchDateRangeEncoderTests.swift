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

    func testIsWithinLocalDaysInclusiveStartExclusiveEndNextDay() {
        let start = date(year: 2024, month: 6, day: 1)
        let end = date(year: 2024, month: 6, day: 2)

        let insideMorning = date(year: 2024, month: 6, day: 1, hour: 0, minute: 0)
        let insideEvening = date(year: 2024, month: 6, day: 2, hour: 23, minute: 59)
        let before = date(year: 2024, month: 5, day: 31, hour: 23, minute: 59)
        let after = date(year: 2024, month: 6, day: 3, hour: 0, minute: 0)

        XCTAssertTrue(
            LaunchDateRangeEncoder.isWithinLocalDays(
                insideMorning, start: start, end: end, calendar: calendar, timeZone: timeZone
            )
        )
        XCTAssertTrue(
            LaunchDateRangeEncoder.isWithinLocalDays(
                insideEvening, start: start, end: end, calendar: calendar, timeZone: timeZone
            )
        )
        XCTAssertFalse(
            LaunchDateRangeEncoder.isWithinLocalDays(
                before, start: start, end: end, calendar: calendar, timeZone: timeZone
            )
        )
        XCTAssertFalse(
            LaunchDateRangeEncoder.isWithinLocalDays(
                after, start: start, end: end, calendar: calendar, timeZone: timeZone
            )
        )
    }

    func testIsWithinLocalDaysNilBoundsAcceptAll() {
        let any = date(year: 2020, month: 1, day: 1)
        XCTAssertTrue(
            LaunchDateRangeEncoder.isWithinLocalDays(
                any, start: nil, end: nil, calendar: calendar, timeZone: timeZone
            )
        )
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
