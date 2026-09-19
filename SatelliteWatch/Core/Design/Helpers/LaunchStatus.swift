import SwiftUI

enum LaunchStatus: Equatable, Sendable {
    case success
    case failure
    case upcoming
    case unknown

    var title: String {
        switch self {
        case .success: "Success"
        case .failure: "Failure"
        case .upcoming: "Upcoming"
        case .unknown: "Unknown"
        }
    }

    var color: Color {
        switch self {
        case .success: AppColor.success
        case .failure: AppColor.danger
        case .upcoming: AppColor.info
        case .unknown: AppColor.neutral
        }
    }

    static func derive(success: Bool?, upcoming: Bool) -> LaunchStatus {
        if let success {
            return success ? .success : .failure
        }
        return upcoming ? .upcoming : .unknown
    }
}

extension Launch {
    var status: LaunchStatus {
        LaunchStatus.derive(success: success, upcoming: upcoming)
    }
}
