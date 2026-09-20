import Foundation

enum DataSourceMode: String, CaseIterable, Identifiable, Sendable {
    case live
    case sample

    static let sampleDataLaunchArgument = "-sampleData"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .live: "Live"
        case .sample: "Sample"
        }
    }

    static func resolve(
        from arguments: [String],
        fallback: DataSourceMode = .live
    ) -> DataSourceMode {
        arguments.contains(sampleDataLaunchArgument) ? .sample : fallback
    }
}
