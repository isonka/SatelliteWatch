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
}
