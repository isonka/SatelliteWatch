import XCTest
@testable import SatelliteWatch

final class DateFormattingTests: XCTestCase {
    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    func testHourPrecisionIncludesTime() {
        let text = DateFormatting.display(date: date, precision: .hour)
        XCTAssertFalse(text.isEmpty)
        XCTAssertNotEqual(text, DateFormatting.dayOnly(date))
    }

    func testDayAndNilUseDayOnly() {
        XCTAssertEqual(
            DateFormatting.display(date: date, precision: .day),
            DateFormatting.dayOnly(date)
        )
        XCTAssertEqual(
            DateFormatting.display(date: date, precision: nil),
            DateFormatting.dayOnly(date)
        )
    }

    func testMonthQuarterYearProduceNonEmptyStrings() {
        XCTAssertFalse(DateFormatting.display(date: date, precision: .month).isEmpty)
        XCTAssertFalse(DateFormatting.display(date: date, precision: .quarter).isEmpty)
        XCTAssertFalse(DateFormatting.display(date: date, precision: .half).isEmpty)
        XCTAssertFalse(DateFormatting.display(date: date, precision: .year).isEmpty)
    }
}
