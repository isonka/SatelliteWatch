import Foundation
@testable import SatelliteWatch

extension LaunchpadSummary {
    static func fixture(
        id: String = "ksc",
        name: String? = "KSC LC 39A",
        fullName: String? = "Kennedy Space Center Historic Launch Complex 39A",
        locality: String? = "Cape Canaveral",
        region: String? = "Florida"
    ) -> LaunchpadSummary {
        LaunchpadSummary(
            id: id,
            name: name,
            fullName: fullName,
            locality: locality,
            region: region
        )
    }
}
