import Foundation

enum SpaceXQueryValue: Encodable, Sendable {
    case string(String)
    case object([String: SpaceXQueryValue])

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}

struct SpaceXQueryOptions: Encodable, Sendable {
    var page: Int
    var limit: Int
    var sort: [String: String]?
    var populate: [String]?
}

struct SpaceXQueryRequest: Encodable, Sendable {
    let query: [String: SpaceXQueryValue]
    let options: SpaceXQueryOptions
}
