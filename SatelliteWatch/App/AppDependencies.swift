import Foundation

@MainActor
struct AppDependencies {
    let spaceXService: any SpaceXServiceProtocol

    static let live = AppDependencies(
        spaceXService: SpaceXAPIClient()
    )

    static let preview = AppDependencies(
        spaceXService: MockSpaceXService()
    )
}
