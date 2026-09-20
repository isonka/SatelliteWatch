import Foundation

enum LaunchLibraryEndpoint {
    static let baseURL = URL(string: "https://ll.thespacedevs.com/2.2.0")!

    static let spaceXAgencyID = 121
    static let launchLimit = 100
    static let rocketLimit = 20
    static let cacheTTL: TimeInterval = 60 * 60

    static var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appending(path: "LaunchLibrary", directoryHint: .isDirectory)
    }

    case upcomingLaunches
    case previousLaunches
    case rockets

    var url: URL {
        let resource = pathComponents.reduce(Self.baseURL) { url, component in
            url.appending(path: component)
        }
        var components = URLComponents(url: resource, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        return components?.url ?? resource
    }

    private var pathComponents: [String] {
        switch self {
        case .upcomingLaunches: ["launch", "upcoming"]
        case .previousLaunches: ["launch", "previous"]
        case .rockets: ["config", "launcher"]
        }
    }

    private var queryItems: [URLQueryItem] {
        switch self {
        case .upcomingLaunches, .previousLaunches:
            [
                URLQueryItem(name: "lsp__id", value: String(Self.spaceXAgencyID)),
                URLQueryItem(name: "limit", value: String(Self.launchLimit))
            ]
        case .rockets:
            [
                URLQueryItem(name: "manufacturer__name", value: "SpaceX"),
                URLQueryItem(name: "limit", value: String(Self.rocketLimit)),
                URLQueryItem(name: "mode", value: "detailed")
            ]
        }
    }
}
