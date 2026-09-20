import Foundation
@testable import SatelliteWatch
import XCTest

final class DateFormattingTests: XCTestCase {
    private let date = Date(timeIntervalSince1970: 1_583_554_231)

    func testHourIncludesTimeUnlikeDayOnly() {
        XCTAssertNotEqual(
            DateFormatting.display(date: date, precision: .hour),
            DateFormatting.dayOnly(date)
        )
    }

    func testDayAndNilHideClockTime() {
        XCTAssertEqual(
            DateFormatting.display(date: date, precision: .day),
            DateFormatting.dayOnly(date)
        )
        XCTAssertEqual(
            DateFormatting.display(date: date, precision: nil),
            DateFormatting.dayOnly(date)
        )
    }

    func testCoarserPrecisionDoesNotUseDayOnly() {
        XCTAssertNotEqual(
            DateFormatting.display(date: date, precision: .month),
            DateFormatting.dayOnly(date)
        )
        XCTAssertNotEqual(
            DateFormatting.display(date: date, precision: .year),
            DateFormatting.dayOnly(date)
        )
    }
}
