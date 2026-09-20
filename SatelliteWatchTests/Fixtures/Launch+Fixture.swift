import Foundation
@testable import SatelliteWatch

extension Launch {
    static func fixture(
        id: String = "launch-1",
        name: String = "Starlink 6-1",
        details: String? = "A batch of Starlink satellites.",
        success: Bool? = true,
        upcoming: Bool = false,
        dateUTC: Date = Date(timeIntervalSince1970: 1_700_000_000),
        datePrecision: DatePrecision? = .hour,
        links: LaunchLinks? = LaunchLinks(
            patch: .init(
                small: "https://images2.imgbox.com/a9/9a/NXVkTST8_o.png",
                large: "https://images2.imgbox.com/a9/9a/NXVkTST8_o.png"
            ),
            webcast: "https://youtu.be/J442-ti-Dhg",
            wikipedia: nil,
            article: nil
        ),
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
