import Foundation
@testable import SatelliteWatch

extension Launch {
    static func fixture(
        id: String = "launch-1",
        name: String = "CRS-20",
        details: String? = "Resupply mission",
        success: Bool? = true,
        upcoming: Bool = false,
        dateUTC: Date = Date(timeIntervalSince1970: 1_583_556_631),
        datePrecision: DatePrecision? = .hour,
        links: LaunchLinks? = .fixture(),
        rocket: RocketRef? = .populated(.fixture()),
        launchpad: LaunchpadRef? = .populated(.fixture())
    ) -> Launch {
        Launch(
            id: id,
            name: name,
            details: details,
            success: success,
            upcoming: upcoming,
            dateUTC: dateUTC,
            datePrecision: datePrecision,
            links: links,
            rocket: rocket,
            launchpad: launchpad
        )
    }
}

extension LaunchLinks {
    static func fixture(
        smallPatch: String? = "https://example.com/small.png",
        largePatch: String? = "https://example.com/large.png",
        webcast: String? = "https://www.youtube.com/watch?v=abc",
        wikipedia: String? = nil,
        article: String? = nil
    ) -> LaunchLinks {
        LaunchLinks(
            patch: .init(small: smallPatch, large: largePatch),
            webcast: webcast,
            wikipedia: wikipedia,
            article: article
        )
    }
}
