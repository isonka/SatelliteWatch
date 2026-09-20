import Foundation

struct LaunchLibraryAPIClient: SpaceXServiceProtocol {
    private let transport: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    init(
        transport: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse) = {
            try await URLSession.shared.data(for: $0)
        }
    ) {
        self.transport = transport
    }

    func fetchLaunches(
        page: Int,
        limit: Int,
        startDate: Date?,
        endDate: Date?
    ) async throws -> PaginatedResponse<Launch> {
        let documents = try await loadLaunches().filter {
            LaunchDateRangeEncoder.isWithinLocalDays($0.dateUTC, start: startDate, end: endDate)
        }
        return Self.paginate(documents, page: page, limit: limit)
    }

    func fetchRockets(page: Int, limit: Int) async throws -> PaginatedResponse<Rocket> {
        return Self.paginate(try await loadRockets(), page: page, limit: limit)
    }

    func fetchRocket(id: String) async throws -> Rocket {
        let documents = try await loadRockets()
        guard let rocket = documents.first(where: { $0.id == id }) else {
            throw SpaceXAPIError.httpStatus(404)
        }
        return rocket
    }

    private func loadRockets() async throws -> [Rocket] {
        let response: LaunchLibraryListResponse<LaunchLibraryRocketDTO> = try await get(
            endpoint: .rockets
        )
        return response.results.map(Rocket.init(library:))
    }

    private func loadLaunches() async throws -> [Launch] {
        async let upcomingResponse: LaunchLibraryListResponse<LaunchLibraryLaunchDTO> = get(
            endpoint: .upcomingLaunches
        )
        async let previousResponse: LaunchLibraryListResponse<LaunchLibraryLaunchDTO> = get(
            endpoint: .previousLaunches
        )
        let (upcoming, previous) = try await (upcomingResponse, previousResponse)

        let previousLaunches = previous.results.map {
            Launch(library: $0, upcoming: false)
        }
        let upcomingLaunches = upcoming.results.map {
            Launch(library: $0, upcoming: true)
        }

        // Previous wins on the 24-hour overlap so a just-flown mission keeps its outcome.
        var seen = Set<String>()
        var merged: [Launch] = []
        for launch in previousLaunches + upcomingLaunches where seen.insert(launch.id).inserted {
            merged.append(launch)
        }
        return merged.sorted { $0.dateUTC > $1.dateUTC }
    }

    private static func paginate<Item>(
        _ documents: [Item],
        page: Int,
        limit: Int
    ) -> PaginatedResponse<Item> {
        let limit = max(1, limit)
        let page = max(1, page)
        let start = min((page - 1) * limit, documents.count)
        let end = min(start + limit, documents.count)
        let totalPages = max(1, Int((Double(documents.count) / Double(limit)).rounded(.up)))

        return PaginatedResponse(
            docs: Array(documents[start..<end]),
            totalDocs: documents.count,
            limit: limit,
            totalPages: totalPages,
            page: page,
            hasNextPage: end < documents.count,
            hasPrevPage: page > 1,
            nextPage: end < documents.count ? page + 1 : nil,
            prevPage: page > 1 ? page - 1 : nil
        )
    }

    private func get<Response: Decodable>(endpoint: LaunchLibraryEndpoint) async throws -> Response {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("SatelliteWatch/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await transport(request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw SpaceXAPIError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw SpaceXAPIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw SpaceXAPIError.httpStatus(http.statusCode)
        }

        do {
            return try SpaceXJSONDecoderFactory.make().decode(Response.self, from: data)
        } catch {
            throw SpaceXAPIError.decoding(error.localizedDescription)
        }
    }
}
