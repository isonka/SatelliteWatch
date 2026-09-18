import Foundation

@MainActor
struct AppDependencies {
    let spaceXService: any SpaceXServiceProtocol

    static let live = AppDependencies(
        spaceXService: MockSpaceXService()
    )

    static let preview = AppDependencies(
        spaceXService: MockSpaceXService()
    )
}
