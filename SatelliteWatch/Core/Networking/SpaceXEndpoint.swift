import Foundation

enum SpaceXEndpoint {
    static let baseURL = URL(string: "https://api.spacexdata.com")!

    case launchesQuery
    case rocketsQuery
    case rocket(id: String)

    var url: URL {
        switch self {
        case .launchesQuery:
            // Mixed versioning: launches on v5
            Self.baseURL.appending(path: "v5/launches/query")
        case .rocketsQuery:
            // Rockets remain on v4
            Self.baseURL.appending(path: "v4/rockets/query")
        case .rocket(let id):
            Self.baseURL.appending(path: "v4/rockets/\(id)")
        }
    }
}
