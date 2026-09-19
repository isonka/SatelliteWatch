import Foundation

enum SpaceXJSONDecoderFactory {
    static func make() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = parseISO8601(value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognized date format: \(value)"
            )
        }
        return decoder
    }

    static func parseISO8601(_ value: String) -> Date? {
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFractional.date(from: value) {
            return date
        }

        let withoutFractional = ISO8601DateFormatter()
        withoutFractional.formatOptions = [.withInternetDateTime]
        return withoutFractional.date(from: value)
    }
}

enum SpaceXJSONEncoderFactory {
    static func make() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
