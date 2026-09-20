import Foundation

struct LaunchLibraryListResponse<Item: Decodable & Sendable>: Decodable, Sendable {
    let count: Int?
    let next: String?
    let previous: String?
    let results: [Item]

    func mappedPage<Document>(
        page: Int,
        limit: Int,
        transform: (Item) -> Document
    ) -> PaginatedResponse<Document> {
        let limit = max(1, limit)
        let page = max(1, page)
        let docs = results.map(transform)
        let totalDocs = count ?? docs.count
        let hasNextPage = !(next?.isEmpty ?? true)
        let hasPrevPage = !(previous?.isEmpty ?? true)
        let totalPages = max(1, Int((Double(totalDocs) / Double(limit)).rounded(.up)))

        return PaginatedResponse(
            docs: docs,
            totalDocs: totalDocs,
            limit: limit,
            totalPages: totalPages,
            page: page,
            hasNextPage: hasNextPage,
            hasPrevPage: hasPrevPage,
            nextPage: hasNextPage ? page + 1 : nil,
            prevPage: hasPrevPage || page > 1 ? max(page - 1, 1) : nil
        )
    }
}

struct LaunchLibraryLaunchDTO: Decodable, Sendable {
    let id: String
    let name: String
    let net: Date
    let image: String?
    let status: Status?
    let netPrecision: Precision?
    let rocket: Rocket?
    let mission: Mission?
    let pad: Pad?
    let program: [Program]?

    struct Status: Decodable, Sendable {
        let id: Int?
        let abbrev: String?
    }

    struct Precision: Decodable, Sendable {
        let abbrev: String?
    }

    struct Rocket: Decodable, Sendable {
        let configuration: Configuration?

        struct Configuration: Decodable, Sendable {
            let id: Int
            let name: String?
            let fullName: String?

            enum CodingKeys: String, CodingKey {
                case id
                case name
                case fullName = "full_name"
            }
        }
    }

    struct Mission: Decodable, Sendable {
        let description: String?
        let infoURLs: [LaunchLibraryLink]?
        let vidURLs: [LaunchLibraryLink]?

        enum CodingKeys: String, CodingKey {
            case description
            case infoURLs = "info_urls"
            case vidURLs = "vid_urls"
        }
    }

    struct Pad: Decodable, Sendable {
        let id: Int?
        let name: String?
        let wikiURL: String?
        let location: Location?

        struct Location: Decodable, Sendable {
            let name: String?
            let countryCode: String?

            enum CodingKeys: String, CodingKey {
                case name
                case countryCode = "country_code"
            }
        }

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case wikiURL = "wiki_url"
            case location
        }
    }

    struct Program: Decodable, Sendable {
        let missionPatches: [MissionPatch]?

        struct MissionPatch: Decodable, Sendable {
            let priority: Int?
            let imageURL: String?

            enum CodingKeys: String, CodingKey {
                case priority
                case imageURL = "image_url"
            }
        }

        enum CodingKeys: String, CodingKey {
            case missionPatches = "mission_patches"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case net
        case image
        case status
        case netPrecision = "net_precision"
        case rocket
        case mission
        case pad
        case program
    }
}

struct LaunchLibraryRocketDTO: Decodable, Sendable {
    let id: Int
    let name: String
    let fullName: String?
    let family: String?
    let description: String?
    let active: Bool?
    let imageURL: String?
    let totalLaunchCount: Int?
    let successfulLaunches: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case family
        case description
        case active
        case imageURL = "image_url"
        case totalLaunchCount = "total_launch_count"
        case successfulLaunches = "successful_launches"
    }
}

struct LaunchLibraryLink: Decodable, Sendable {
    let url: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let url = try? container.decode(String.self) {
            self.url = url
            return
        }

        let object = try decoder.container(keyedBy: CodingKeys.self)
        url = try object.decode(String.self, forKey: .url)
    }

    private enum CodingKeys: String, CodingKey {
        case url
    }
}
