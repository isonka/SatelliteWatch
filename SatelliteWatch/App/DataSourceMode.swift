import Foundation

enum DataSourceMode: String, CaseIterable, Identifiable, Sendable {
    case live
    case sample

    var id: String { rawValue }

    var title: String {
        switch self {
        case .live: "Live"
        case .sample: "Sample"
        }
    }
}
