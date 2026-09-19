import Foundation
@testable import SatelliteWatch

extension Rocket {
    static func fixture(
        id: String = "falcon9",
        name: String = "Falcon 9",
        type: String? = "rocket",
        active: Bool? = true,
        description: String? = "Reusable rocket",
        successRatePct: Double? = 97,
        flickrImages: [String]? = ["https://example.com/rocket.jpg"],
        engines: RocketEngines? = .fixture()
    ) -> Rocket {
        Rocket(
            id: id,
            name: name,
            type: type,
            active: active,
            description: description,
            successRatePct: successRatePct,
            flickrImages: flickrImages,
            engines: engines
        )
    }
}

extension RocketEngines {
    static func fixture(
        number: Int? = 9,
        type: String? = "merlin",
        version: String? = "1D+"
    ) -> RocketEngines {
        RocketEngines(number: number, type: type, version: version)
    }
}
