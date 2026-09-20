import SwiftUI

struct RocketDetailView: View {
    let rocket: Rocket

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                RemoteImageView(url: rocket.primaryImageURL, height: 240)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(rocket.name)
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    labeledRow("Type", rocket.type ?? "Unknown")
                    labeledRow("Status", activeText)
                    labeledRow("Engines", enginesText)

                    Text(descriptionText)
                        .font(AppFont.body)
                        .foregroundStyle(hasDescription ? AppColor.primaryText : AppColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.bottom, Spacing.xl)
        }
        .navigationTitle("Rocket")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("rocket-detail-\(rocket.id)")
    }

    private var hasDescription: Bool {
        !(rocket.description?.isEmpty ?? true)
    }

    private var descriptionText: String {
        hasDescription ? rocket.description! : "No description available."
    }

    private var activeText: String {
        switch rocket.active {
        case true: "Active"
        case false: "Inactive"
        case nil: "Unknown"
        }
    }

    private var enginesText: String {
        let number = rocket.engines?.number.map(String.init) ?? "—"
        let type = rocket.engines?.type ?? "unknown type"
        let version = rocket.engines?.version.map { " \($0)" } ?? ""
        return "\(number) × \(type)\(version)"
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs / 2) {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryText)
            Text(value)
                .font(AppFont.subheadline)
                .foregroundStyle(AppColor.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value)")
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        RocketDetailView(rocket: MockSpaceXService.previewRocket)
    }
}
#endif
