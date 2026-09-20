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

    init(dataSourceMode: DataSourceMode? = nil) {
        #if DEBUG
        let mode = dataSourceMode ?? DataSourceMode.resolve(
            from: ProcessInfo.processInfo.arguments
        )
        #else
        let mode = dataSourceMode ?? .live
        #endif
        self.dataSourceMode = mode
        self.spaceXService = Self.makeService(for: mode)
    }

    static var preview: AppDependencies {
        AppDependencies(dataSourceMode: .sample)
    }

    private static func makeService(for mode: DataSourceMode) -> any SpaceXServiceProtocol {
        switch mode {
        case .live:
            SpaceXAPIClient()
        case .mirror:
            LaunchLibraryAPIClient(cacheDirectory: LaunchLibraryEndpoint.cacheDirectory)
        case .sample:
            MockSpaceXService()
        }
    }
}
