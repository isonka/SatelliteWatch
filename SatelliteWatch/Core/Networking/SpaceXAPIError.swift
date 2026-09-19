import Foundation

enum SpaceXAPIError: Error, Equatable, LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not build a valid API request."
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .httpStatus(let code):
            return "The server returned status code \(code)."
        case .decoding:
            return "Could not understand the server response."
        case .transport(let message):
            return message
        }
    }
}
