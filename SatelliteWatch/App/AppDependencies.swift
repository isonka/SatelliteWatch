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

    private(set) var spaceXService: any ServiceProtocol

    init(dataSourceMode: DataSourceMode? = nil) {
        #if DEBUG
        let fallback: DataSourceMode = Self.isRunningUnitTests ? .sample : .mirror
        let mode = dataSourceMode ?? DataSourceMode.resolve(
            from: ProcessInfo.processInfo.arguments,
            fallback: fallback
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

    #if DEBUG
    static let isRunningUnitTests =
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    #endif

    private static func makeService(for mode: DataSourceMode) -> any ServiceProtocol {
        switch mode {
        case .live:
            SpaceXAPIClient()
        case .mirror:
            LaunchLibraryAPIClient()
        case .sample:
            MockSpaceXService()
        }
    }
}
