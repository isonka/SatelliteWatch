import SwiftUI

struct RocketCardView: View {
    let rocket: Rocket

    var body: some View {
        HStack(spacing: Spacing.md) {
            RemoteImageView(url: rocket.primaryImageURL, height: 72)
                .frame(width: 72, height: 72)
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
                Text("Tap for rocket details")
                    .font(AppFont.caption)
                    .foregroundStyle(.tint)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(AppFont.footnote.weight(.semibold))
                .foregroundStyle(AppColor.secondaryText)
        }
        .padding(Spacing.md)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rocket \(rocket.name), type \(rocket.type ?? "unknown")")
        .accessibilityHint("Opens rocket details")
        .accessibilityIdentifier("rocket-card-\(rocket.id)")
    }
}
