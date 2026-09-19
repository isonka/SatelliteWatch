import Foundation
import Observation

@Observable
@MainActor
final class AppDependencies {
    var dataSourceMode: DataSourceMode {
        didSet {
            guard oldValue != dataSourceMode else { return }
            spaceXService = Self.makeService(for: dataSourceMode)
        }
    }

    private(set) var spaceXService: any SpaceXServiceProtocol

    init(dataSourceMode: DataSourceMode = .live) {
        #if DEBUG
        let mode = dataSourceMode
        #else
        let mode = DataSourceMode.live
        #endif
        self.dataSourceMode = mode
        self.spaceXService = Self.makeService(for: mode)
    }

    static var live: AppDependencies {
        AppDependencies(dataSourceMode: .live)
    }

    static var preview: AppDependencies {
        AppDependencies(dataSourceMode: .sample)
    }

    var isUsingSampleData: Bool {
        dataSourceMode == .sample
    }

    private static func makeService(for mode: DataSourceMode) -> any SpaceXServiceProtocol {
        switch mode {
        case .live:
            SpaceXAPIClient()
        case .sample:
            MockSpaceXService()
        }
    }
}
