import Foundation

enum DataSourceMode: String, CaseIterable, Identifiable, Sendable {
    case live
    case mirror
    case sample

    static let sampleDataLaunchArgument = "-sampleData"
    static let mirrorDataLaunchArgument = "-mirrorData"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .live: "SpaceX API"
        case .mirror: "Launch Library 2"
        case .sample: "Sample data"
        }
    }
    
    var baseURLDescription: String? {
        switch self {
        case .live: SpaceXEndpoint.baseURL.absoluteString
        case .mirror: LaunchLibraryEndpoint.baseURL.absoluteString
        case .sample: nil
        }
    }
    
    var host: String? {
        switch self {
        case .live: SpaceXEndpoint.baseURL.host()
        case .mirror: LaunchLibraryEndpoint.baseURL.host()
        case .sample: nil
        }
    }
    
    var menuTitle: String {
        guard let host else { return title }
        return "\(title) — \(host)"
    }

    var symbolName: String {
        switch self {
        case .live: "network"
        case .mirror: "arrow.triangle.branch"
        case .sample: "shippingbox"
        }
    }

    var isNetworkBacked: Bool {
        baseURLDescription != nil
    }

    static func resolve(
        from arguments: [String],
        fallback: DataSourceMode = .live
    ) -> DataSourceMode {
        if arguments.contains(sampleDataLaunchArgument) {
            return .sample
        }
        if arguments.contains(mirrorDataLaunchArgument) {
            return .mirror
        }
        return fallback
    }
}
