import Foundation

enum SpaceXEndpoint {
    static let baseURL = URL(string: "https://api.spacexdata.com")!

    case launchesQuery
    case rocketsQuery
    case rocket(id: String)

    var url: URL {
        switch self {
        case .launchesQuery:
            Self.baseURL.appending(path: "v5/launches/query")
        case .rocketsQuery:
            Self.baseURL.appending(path: "v4/rockets/query")
        case .rocket(let id):
            Self.baseURL.appending(path: "v4/rockets/\(id)")
        }
    }
}
