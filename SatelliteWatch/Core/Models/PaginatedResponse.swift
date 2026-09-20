import Foundation

struct PaginatedResponse<Document: Decodable & Sendable>: Decodable, Sendable {
    let docs: [Document]
    let totalDocs: Int
    let limit: Int
    let totalPages: Int
    let page: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
    let nextPage: Int?
    let prevPage: Int?

    enum CodingKeys: String, CodingKey {
        case docs
        case totalDocs
        case limit
        case totalPages
        case page
        case hasNextPage
        case hasPrevPage
        case nextPage
        case prevPage
    }

    init(
        docs: [Document],
        totalDocs: Int? = nil,
        limit: Int = 20,
        totalPages: Int = 1,
        page: Int,
        hasNextPage: Bool,
        hasPrevPage: Bool = false,
        nextPage: Int? = nil,
        prevPage: Int? = nil
    ) {
        self.docs = docs
        self.totalDocs = totalDocs ?? docs.count
        self.limit = limit
        self.totalPages = totalPages
        self.page = page
        self.hasNextPage = hasNextPage
        self.hasPrevPage = hasPrevPage
        self.nextPage = nextPage
        self.prevPage = prevPage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        docs = try container.decode([Document].self, forKey: .docs)
        page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
        hasNextPage = try container.decodeIfPresent(Bool.self, forKey: .hasNextPage) ?? false
        totalDocs = try container.decodeIfPresent(Int.self, forKey: .totalDocs) ?? docs.count
        limit = try container.decodeIfPresent(Int.self, forKey: .limit) ?? docs.count
        totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages) ?? 1
        hasPrevPage = try container.decodeIfPresent(Bool.self, forKey: .hasPrevPage) ?? false
        nextPage = try container.decodeIfPresent(Int.self, forKey: .nextPage)
        prevPage = try container.decodeIfPresent(Int.self, forKey: .prevPage)
    }
}
