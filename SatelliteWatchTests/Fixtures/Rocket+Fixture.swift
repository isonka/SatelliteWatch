import Foundation
@testable import SatelliteWatch

extension Rocket {
    static func fixture(
        id: String = "falcon9",
        name: String = "Falcon 9",
        type: String? = "rocket",
        active: Bool? = true,
        description: String? = "Two-stage orbital rocket.",
        successRatePct: Double? = 98,
        flickrImages: [String]? = ["https://farm1.staticflickr.com/929/example.jpg"],
        engines: RocketEngines? = RocketEngines(number: 9, type: "merlin", version: "1D+")
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
