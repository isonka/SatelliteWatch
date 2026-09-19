import Foundation

struct LaunchpadSummary: Codable, Sendable, Equatable, Identifiable {
    let id: String
    let name: String?
    let fullName: String?
    let locality: String?
    let region: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case locality
        case region
    }

    var displayName: String {
        fullName ?? name ?? "Unknown launch site"
    }
}
