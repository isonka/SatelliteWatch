import SwiftUI

struct RocketRowView: View {
    let rocket: Rocket

    var body: some View {
        HStack(spacing: Spacing.md) {
            RemoteImageView(url: rocket.primaryImageURL, height: 64)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(rocket.name)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(rocket.type ?? "Unknown type")
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(successRateText)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryText)
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(rocket.name), \(rocket.type ?? "unknown type"), \(successRateText)")
        .accessibilityHint("Opens rocket details")
        .accessibilityIdentifier("rocket-row-\(rocket.id)")
    }

    private var successRateText: String {
        if let rate = rocket.successRatePct {
            return String(format: "Success rate %.0f%%", rate)
        }
        return "Success rate unavailable"
    }
}

#if DEBUG
#Preview {
    List {
        RocketRowView(rocket: MockSpaceXService.previewRocket)
    }
}
#endif
