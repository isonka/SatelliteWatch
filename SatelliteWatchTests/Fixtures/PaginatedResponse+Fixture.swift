import Foundation
@testable import SatelliteWatch

extension PaginatedResponse {
    static func fixture(
        docs: [Document],
        page: Int = 1,
        hasNextPage: Bool = false,
        limit: Int = 20
    ) -> PaginatedResponse<Document> {
        PaginatedResponse(
            docs: docs,
            totalDocs: docs.count,
            limit: limit,
            totalPages: hasNextPage ? page + 1 : page,
            page: page,
            hasNextPage: hasNextPage,
            hasPrevPage: page > 1,
            nextPage: hasNextPage ? page + 1 : nil,
            prevPage: page > 1 ? page - 1 : nil
        )
    }
}
