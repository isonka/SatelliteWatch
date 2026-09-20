import Foundation

enum HTTPURL {
    static func parse(_ string: String?) -> URL? {
        guard let string, let url = URL(string: string), isAllowed(url) else {
            return nil
        }
        return url
    }

    static func isAllowed(_ url: URL) -> Bool {
        switch url.scheme?.lowercased() {
        case "http", "https":
            true
        default:
            false
        }
    }
}
