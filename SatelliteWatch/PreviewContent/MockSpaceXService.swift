import Foundation

struct MockSpaceXService: SpaceXServiceProtocol {
    static var previewLaunches: [Launch] { sampleLaunches }
    static var previewRocket: Rocket { sampleRocket }

    func fetchLaunches(
        page: Int,
        limit: Int,
        startDate: Date?,
        endDate: Date?
    ) async throws -> PaginatedResponse<Launch> {
        var docs = Self.sampleLaunches
        let calendar = Calendar.current

        if let startDate {
            let start = calendar.startOfDay(for: startDate)
            docs = docs.filter { $0.dateUTC >= start }
        }
        if let endDate {
            let startOfEnd = calendar.startOfDay(for: endDate)
            let endExclusive = calendar.date(byAdding: .day, value: 1, to: startOfEnd) ?? startOfEnd
            docs = docs.filter { $0.dateUTC < endExclusive }
        }

        return PaginatedResponse(
            docs: docs,
            totalDocs: docs.count,
            limit: limit,
            totalPages: 1,
            page: page,
            hasNextPage: false,
            hasPrevPage: false,
            nextPage: nil,
            prevPage: nil
        )
    }

    func fetchRockets(
        page: Int,
        limit: Int
    ) async throws -> PaginatedResponse<Rocket> {
        let docs = [Self.sampleRocket]
        return PaginatedResponse(
            docs: docs,
            totalDocs: docs.count,
            limit: limit,
            totalPages: 1,
            page: page,
            hasNextPage: false,
            hasPrevPage: false,
            nextPage: nil,
            prevPage: nil
        )
    }

    func fetchRocket(id: String) async throws -> Rocket {
        var rocket = Self.sampleRocket
        if id != rocket.id {
            rocket = Rocket(
                id: id,
                name: "Mock Rocket",
                type: "rocket",
                active: true,
                description: nil,
                successRatePct: nil,
                flickrImages: nil,
                engines: nil
            )
        }
        return rocket
    }
}

private extension MockSpaceXService {
    static let sampleRocket = Rocket(
        id: "falcon9",
        name: "Falcon 9",
        type: "rocket",
        active: true,
        description: "Falcon 9 is a two-stage rocket designed and manufactured by SpaceX.",
        successRatePct: 98,
        flickrImages: ["https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcREofow3jHyl-4BTmXcxPPc76_PUm4inuy7o4qC7e9R2g"],
        engines: RocketEngines(number: 9, type: "merlin", version: "1D+")
    )

    static let sampleLaunchpad = LaunchpadSummary(
        id: "ksc",
        name: "KSC LC 39A",
        fullName: "Kennedy Space Center Historic Launch Complex 39A",
        locality: "Cape Canaveral",
        region: "Florida"
    )

    static var sampleLaunches: [Launch] {
        [
            Launch(
                id: "launch-1",
                name: "Starlink 6-1",
                details: "A batch of Starlink satellites.",
                success: true,
                upcoming: false,
                dateUTC: Date(timeIntervalSince1970: 1_700_000_000),
                datePrecision: .hour,
                links: LaunchLinks(
                    patch: .init(
                        small: "https://images2.imgbox.com/a9/9a/NXVkTST8_o.png",
                        large: "https://images2.imgbox.com/a9/9a/NXVkTST8_o.png"
                    ),
                    webcast: "https://youtu.be/J442-ti-Dhg",
                    wikipedia: nil,
                    article: nil
                ),
                rocket: .populated(sampleRocket),
                launchpad: .populated(sampleLaunchpad)
            ),
            Launch(
                id: "launch-2",
                name: "Crew-10",
                details: nil,
                success: nil,
                upcoming: true,
                dateUTC: Date(timeIntervalSince1970: 1_800_000_000),
                datePrecision: .day,
                links: nil,
                rocket: .populated(sampleRocket),
                launchpad: .populated(sampleLaunchpad)
            )
        ]
    }
}
