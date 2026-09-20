import Foundation

struct LaunchLinks: Codable, Sendable, Equatable, Hashable {
    let patch: PatchLinks?
    let webcast: String?
    let wikipedia: String?
    let article: String?

    struct PatchLinks: Codable, Sendable, Equatable, Hashable {
        let small: String?
        let large: String?
    }
}

struct Launch: Codable, Sendable, Equatable, Hashable, Identifiable {
    let id: String
    let name: String
    let details: String?
    let success: Bool?
    let upcoming: Bool
    let dateUTC: Date
    let datePrecision: DatePrecision?
    let links: LaunchLinks?
    let rocket: RocketRef?
    let launchpad: LaunchpadRef

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case details
        case success
        case upcoming
        case dateUTC = "date_utc"
        case datePrecision = "date_precision"
        case links
        case rocket
        case launchpad
    }

    var patchImageURL: URL? {
        [links?.patch?.large, links?.patch?.small]
            .compactMap { $0 }
            .compactMap(URL.init(string:))
            .first
    }

    var webcastURL: URL? {
        guard let webcast = links?.webcast,
              let url = URL(string: webcast),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            return nil
        }
        return url
    }

    var launchSiteName: String {
        switch launchpad {
        case .id:
            return "Unknown launch site"
        case .populated(let pad):
            return pad.displayName
        }
    }

    var populatedRocket: Rocket? {
        if case .populated(let rocket) = rocket {
            return rocket
        }
        return nil
    }

    var hasRocketReference: Bool {
        rocket != nil
    }
}

enum RocketRef: Codable, Sendable, Equatable, Hashable {
    case id(String)
    case populated(Rocket)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let id = try? container.decode(String.self) {
            self = .id(id)
            return
        }
        self = .populated(try container.decode(Rocket.self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .id(let id):
            try container.encode(id)
        case .populated(let rocket):
            try container.encode(rocket)
        }
    }

    var id: String {
        switch self {
        case .id(let id): id
        case .populated(let rocket): rocket.id
        }
    }
}

enum LaunchpadRef: Codable, Sendable, Equatable, Hashable {
    case id(String)
    case populated(LaunchpadSummary)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let id = try? container.decode(String.self) {
            self = .id(id)
            return
        }
        self = .populated(try container.decode(LaunchpadSummary.self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .id(let id):
            try container.encode(id)
        case .populated(let pad):
            try container.encode(pad)
        }
    }
}
