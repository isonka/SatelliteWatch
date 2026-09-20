import Foundation

enum SpaceXAPIError: Error, Equatable, LocalizedError, Sendable {
    case invalidResponse
    case httpStatus(Int)
    case decoding(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received an unexpected response. Please try again."
        case .httpStatus(let code):
            return Self.userMessage(forHTTPStatus: code)
        case .decoding:
            return "Data could not be read. Please try again later."
        case .transport:
            return "Unable to connect. Check your internet connection and try again."
        }
    }

    var debugDescription: String {
        switch self {
        case .invalidResponse:
            return "invalidResponse"
        case .httpStatus(let code):
            return "httpStatus(\(code))"
        case .decoding(let detail):
            return "decoding(\(detail))"
        case .transport(let detail):
            return "transport(\(detail))"
        }
    }

    private static func userMessage(forHTTPStatus code: Int) -> String {
        switch code {
        case 401, 403:
            return "Access to launch data was denied. Please try again later."
        case 404:
            return "The requested data could not be found."
        case 408:
            return "The request timed out. Please try again."
        case 429:
            return "Too many requests. Wait and try again."
        case 500...599:
            if code == 525 {
                return "The SpaceX API is archived and unavailable right now. Try again later."
            }
            return "Launch data is temporarily unavailable. Please try again later."
        default:
            return "Unable to load data right now. Please try again."
        }
    }
}
