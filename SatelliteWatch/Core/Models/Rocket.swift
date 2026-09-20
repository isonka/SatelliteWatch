import Foundation

struct RocketEngines: Codable, Sendable, Equatable, Hashable {
    let number: Int?
    let type: String?
    let version: String?
}

struct Rocket: Codable, Sendable, Equatable, Hashable, Identifiable {
    let id: String
    let name: String
    let type: String?
    let active: Bool?
    let description: String?
    let successRatePct: Double?
    let flickrImages: [String]?
    let engines: RocketEngines?

    func launches(from launches: [Launch]) -> [Launch] {
        launches.filter { $0.rocket?.id == id }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case active
        case description
        case successRatePct = "success_rate_pct"
        case flickrImages = "flickr_images"
        case engines
    }

    var primaryImageURL: URL? {
        flickrImages?
            .compactMap(URL.init(string:))
            .first
    }
}
