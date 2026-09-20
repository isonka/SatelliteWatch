import Foundation

enum LaunchLibraryEndpoint {
    static let baseURL = URL(string: "https://ll.thespacedevs.com/2.2.0")!
    static let spaceXAgencyID = 121

    case launches(page: Int, limit: Int, startUTC: String?, endUTC: String?)
    case rockets(page: Int, limit: Int)
    case rocket(id: String)

    var url: URL {
        let resource = pathComponents.reduce(Self.baseURL) { url, component in
            url.appending(path: component)
        }
        guard let queryItems, !queryItems.isEmpty else {
            return resource
        }
        var components = URLComponents(url: resource, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        return components?.url ?? resource
    }

    static func offset(page: Int, limit: Int) -> Int {
        let limit = max(1, limit)
        let page = max(1, page)
        return (page - 1) * limit
    }

    private var pathComponents: [String] {
        switch self {
        case .launches:
            ["launch"]
        case .rockets:
            ["config", "launcher"]
        case .rocket(let id):
            ["config", "launcher", id]
        }
    }

    private var queryItems: [URLQueryItem]? {
        switch self {
        case let .launches(page, limit, startUTC, endUTC):
            var items = [
                URLQueryItem(name: "lsp__id", value: String(Self.spaceXAgencyID)),
                URLQueryItem(name: "limit", value: String(max(1, limit))),
                URLQueryItem(name: "offset", value: String(Self.offset(page: page, limit: limit))),
                URLQueryItem(name: "ordering", value: "-net")
            ]
            if let startUTC {
                items.append(URLQueryItem(name: "net__gte", value: startUTC))
            }
            if let endUTC {
                items.append(URLQueryItem(name: "net__lte", value: endUTC))
            }
            return items
        case let .rockets(page, limit):
            return [
                URLQueryItem(name: "manufacturer__name", value: "SpaceX"),
                URLQueryItem(name: "limit", value: String(max(1, limit))),
                URLQueryItem(name: "offset", value: String(Self.offset(page: page, limit: limit))),
                URLQueryItem(name: "mode", value: "detailed")
            ]
        case .rocket:
            return nil
        }
    }
}
