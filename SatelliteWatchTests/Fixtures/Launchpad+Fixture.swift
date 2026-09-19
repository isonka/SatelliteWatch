import Foundation
@testable import SatelliteWatch

extension LaunchpadSummary {
    static func fixture(
        id: String = "ccafs_slc_40",
        name: String? = "CCAFS SLC 40",
        fullName: String? = "Cape Canaveral Air Force Station Space Launch Complex 40",
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
