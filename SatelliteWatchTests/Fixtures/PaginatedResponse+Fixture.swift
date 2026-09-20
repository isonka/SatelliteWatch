import Foundation
@testable import SatelliteWatch

extension PaginatedResponse {
    static func page(
        _ docs: [Document],
        page: Int = 1,
        limit: Int = 20,
        hasNextPage: Bool = false,
        hasPrevPage: Bool = false,
        totalPages: Int? = nil,
        totalDocs: Int? = nil
    ) -> PaginatedResponse<Document> {
        let resolvedTotalPages = totalPages ?? (hasNextPage ? page + 1 : max(page, 1))
        return PaginatedResponse(
            docs: docs,
            totalDocs: totalDocs ?? docs.count,
            limit: limit,
            totalPages: resolvedTotalPages,
            page: page,
            hasNextPage: hasNextPage,
            hasPrevPage: hasPrevPage,
            nextPage: hasNextPage ? page + 1 : nil,
            prevPage: hasPrevPage ? page - 1 : nil
        )
    }
}
