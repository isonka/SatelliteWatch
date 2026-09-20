import XCTest
@testable import SatelliteWatch

final class DateFormattingTests: XCTestCase {
    private let locale = Locale(identifier: "en_US")
    private let utc = TimeZone(secondsFromGMT: 0)!

    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    private func display(_ precision: DatePrecision?) -> String {
        DateFormatting.display(date: date, precision: precision, locale: locale, timeZone: utc)
    }

    func testHourPrecisionIncludesTimeOfDay() {
        XCTAssertEqual(asciiSpaces(display(.hour)), "Nov 14, 2023 at 10:13 PM")
    }

    func testDayPrecisionOmitsTimeOfDay() {
        XCTAssertEqual(display(.day), "Nov 14, 2023")
    }

    func testNilPrecisionIsTreatedAsDay() {
        XCTAssertEqual(display(nil), display(.day))
    }

    func testMonthPrecisionDropsTheDay() {
        XCTAssertEqual(display(.month), "Nov 2023")
    }

    func testQuarterHalfAndYearAllCollapseToTheYear() {
        XCTAssertEqual(display(.quarter), "2023")
        XCTAssertEqual(display(.half), "2023")
        XCTAssertEqual(display(.year), "2023")
    }

    func testDayOnlyMatchesDayPrecision() {
        XCTAssertEqual(
            DateFormatting.dayOnly(date, locale: locale, timeZone: utc),
            display(.day)
        )
    }

    func testTimeZoneShiftsTheRenderedDay() {
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        XCTAssertEqual(
            DateFormatting.display(date: date, precision: .day, locale: locale, timeZone: tokyo),
            "Nov 15, 2023"
        )
    }

    /// Foundation may insert NNBSP/NBSP before AM/PM (iOS 16+). Compare on ASCII spaces.
    private func asciiSpaces(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
    }
}
