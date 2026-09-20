import Foundation

extension Launch {
    init(library dto: LaunchLibraryLaunchDTO, upcoming: Bool) {
        let patchURL = dto.preferredImageURL
        let patch = patchURL.map {
            LaunchLinks.PatchLinks(small: $0, large: $0)
        }

        let pad = dto.pad
        let launchpad: LaunchpadRef = {
            guard let pad, pad.name != nil || pad.id != nil else {
                return .id("unknown")
            }
            return .populated(
                LaunchpadSummary(
                    id: pad.id.map(String.init) ?? "unknown",
                    name: pad.name,
                    fullName: pad.name,
                    locality: pad.location?.name,
                    region: pad.location?.countryCode
                )
            )
        }()

        self.init(
            id: dto.id,
            name: dto.name,
            details: dto.mission?.description,
            success: upcoming ? nil : dto.successFlag,
            upcoming: upcoming,
            dateUTC: dto.net,
            datePrecision: DatePrecision(libraryAbbrev: dto.netPrecision?.abbrev),
            links: LaunchLinks(
                patch: patch,
                webcast: dto.mission?.vidURLs?.first?.url,
                wikipedia: pad?.wikiURL,
                article: dto.mission?.infoURLs?.first?.url
            ),
            rocket: dto.rocket?.configuration.map { .id(String($0.id)) },
            launchpad: launchpad
        )
    }
}

extension Rocket {
    init(library dto: LaunchLibraryRocketDTO) {
        let successRate: Double?
        if let total = dto.totalLaunchCount, total > 0, let successful = dto.successfulLaunches {
            successRate = (Double(successful) / Double(total)) * 100
        } else {
            successRate = nil
        }

        self.init(
            id: String(dto.id),
            name: dto.fullName ?? dto.name,
            type: dto.family,
            active: dto.active,
            description: dto.description,
            successRatePct: successRate,
            flickrImages: dto.imageURL.map { [$0] },
            engines: nil
        )
    }
}

extension DatePrecision {
    init?(libraryAbbrev abbrev: String?) {
        switch abbrev?.uppercased() {
        case "SEC", "MIN", "HOUR":
            self = .hour
        case "DAY":
            self = .day
        case "WEEK", "MONTH":
            self = .month
        case "QTR":
            self = .quarter
        case "HALF":
            self = .half
        case "YEAR", "DEC":
            self = .year
        default:
            return nil
        }
    }
}

private extension LaunchLibraryLaunchDTO {
    var preferredImageURL: String? {
        let patches = program?
            .flatMap { $0.missionPatches ?? [] }
            .sorted { ($0.priority ?? 0) > ($1.priority ?? 0) }
            .compactMap(\.imageURL) ?? []
        return patches.first ?? image
    }

    var successFlag: Bool? {
        switch status?.id {
        case .some(3):
            true
        case .some(4), .some(7):
            false
        default:
            switch status?.abbrev?.uppercased() {
            case .some("SUCCESS"): true
            case .some("FAILURE"), .some("PARTIAL FAILURE"): false
            default: nil
            }
        }
    }
}
