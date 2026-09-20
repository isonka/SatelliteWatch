import Foundation

struct LaunchLibraryAPIClient: SpaceXServiceProtocol {
    private let transport: @Sendable (URLRequest) async throws -> (Data, URLResponse)
    private let decoder: JSONDecoder
    private let snapshot: LaunchLibrarySnapshot

    init(
        transport: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse) = {
            try await URLSession.shared.data(for: $0)
        },
        decoder: JSONDecoder = SpaceXJSONDecoderFactory.make(),
        now: @escaping @Sendable () -> Date = { Date() },
        cacheTTL: TimeInterval = LaunchLibraryEndpoint.cacheTTL,
        cacheDirectory: URL? = nil
    ) {
        self.transport = transport
        self.decoder = decoder
        snapshot = LaunchLibrarySnapshot(
            now: now,
            cacheTTL: cacheTTL,
            cacheDirectory: cacheDirectory
        )
    }

    func fetchLaunches(
        page: Int,
        limit: Int,
        startDate: Date?,
        endDate: Date?
    ) async throws -> PaginatedResponse<Launch> {
        let documents = try await snapshot.launches {
            try await loadLaunches()
        }

        let filtered = documents.filter {
            LaunchDateRangeEncoder.isWithinLocalDays($0.dateUTC, start: startDate, end: endDate)
        }
        return Self.paginate(filtered, page: page, limit: limit)
    }

    func fetchRockets(page: Int, limit: Int) async throws -> PaginatedResponse<Rocket> {
        let documents = try await loadRockets()
        return Self.paginate(documents, page: page, limit: limit)
    }

    func fetchRocket(id: String) async throws -> Rocket {
        let documents = try await loadRockets()

        guard let rocket = documents.first(where: { $0.id == id }) else {
            throw SpaceXAPIError.httpStatus(404)
        }
        return rocket
    }

    private func loadRockets() async throws -> [Rocket] {
        try await snapshot.rockets {
            let response: LaunchLibraryListResponse<LaunchLibraryRocketDTO> = try await get(
                endpoint: .rockets
            )
            return response.results.map(Rocket.init(library:))
        }
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
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw SpaceXAPIError.decoding(error.localizedDescription)
        }
    }
}

private actor LaunchLibrarySnapshot {
    private struct Entry<Item> {
        var items: [Item]
        var fetchedAt: Date
    }

    private struct DiskEntry<Item: Codable>: Codable {
        var fetchedAt: Date
        var items: [Item]
    }

    private let now: @Sendable () -> Date
    private let cacheTTL: TimeInterval
    private let cacheDirectory: URL?
    private let cacheDecoder = SpaceXJSONDecoderFactory.make()
    private let cacheEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private var launches: Entry<Launch>?
    private var rockets: Entry<Rocket>?
    private var launchesInFlight: Task<[Launch], Error>?
    private var rocketsInFlight: Task<[Rocket], Error>?

    init(
        now: @escaping @Sendable () -> Date,
        cacheTTL: TimeInterval,
        cacheDirectory: URL?
    ) {
        self.now = now
        self.cacheTTL = cacheTTL
        self.cacheDirectory = cacheDirectory
    }

    func launches(load: @escaping @Sendable () async throws -> [Launch]) async throws -> [Launch] {
        if let launches, isFresh(launches.fetchedAt) {
            return launches.items
        }

        if let disk: Entry<Launch> = readDisk(fileName: "launches.json"), isFresh(disk.fetchedAt) {
            launches = disk
            return disk.items
        }

        if let launchesInFlight {
            return try await launchesInFlight.value
        }

        let task = Task { try await load() }
        launchesInFlight = task
        defer { launchesInFlight = nil }

        do {
            let items = try await task.value
            let entry = Entry(items: items, fetchedAt: now())
            launches = entry
            writeDisk(entry, fileName: "launches.json")
            return items
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if let launches {
                return launches.items
            }
            if let disk: Entry<Launch> = readDisk(fileName: "launches.json") {
                launches = disk
                return disk.items
            }
            throw error
        }
    }

    func rockets(load: @escaping @Sendable () async throws -> [Rocket]) async throws -> [Rocket] {
        if let rockets, isFresh(rockets.fetchedAt) {
            return rockets.items
        }

        if let disk: Entry<Rocket> = readDisk(fileName: "rockets.json"), isFresh(disk.fetchedAt) {
            rockets = disk
            return disk.items
        }

        if let rocketsInFlight {
            return try await rocketsInFlight.value
        }

        let task = Task { try await load() }
        rocketsInFlight = task
        defer { rocketsInFlight = nil }

        do {
            let items = try await task.value
            let entry = Entry(items: items, fetchedAt: now())
            rockets = entry
            writeDisk(entry, fileName: "rockets.json")
            return items
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if let rockets {
                return rockets.items
            }
            if let disk: Entry<Rocket> = readDisk(fileName: "rockets.json") {
                rockets = disk
                return disk.items
            }
            throw error
        }
    }

    private func isFresh(_ fetchedAt: Date) -> Bool {
        now().timeIntervalSince(fetchedAt) < cacheTTL
    }

    private func readDisk<Item: Codable>(fileName: String) -> Entry<Item>? {
        guard let url = cacheDirectory?.appending(path: fileName) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let file = try? cacheDecoder.decode(DiskEntry<Item>.self, from: data) else {
            return nil
        }
        return Entry(items: file.items, fetchedAt: file.fetchedAt)
    }

    private func writeDisk<Item: Codable>(_ entry: Entry<Item>, fileName: String) {
        guard let cacheDirectory else { return }
        let url = cacheDirectory.appending(path: fileName)
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
        let file = DiskEntry(fetchedAt: entry.fetchedAt, items: entry.items)
        guard let data = try? cacheEncoder.encode(file) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
