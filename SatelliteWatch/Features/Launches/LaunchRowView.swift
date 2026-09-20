import SwiftUI

struct LaunchRowView: View {
    let launch: Launch

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(launch.name)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Spacing.sm)
                StatusBadge(status: launch.status)
                    .fixedSize()
            }

            Text(launch.launchSiteName)
                .font(AppFont.subheadline)
                .foregroundStyle(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(DateFormatting.display(date: launch.dateUTC, precision: launch.datePrecision))
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Opens launch details")
        .accessibilityIdentifier("launch-row-\(launch.id)")
    }

    private var accessibilityDescription: String {
        [
            launch.name,
            launch.status.title,
            launch.launchSiteName,
            DateFormatting.display(date: launch.dateUTC, precision: launch.datePrecision)
        ].joined(separator: ", ")
    }
}

#Preview {
    List {
        LaunchRowView(
            launch: Launch(
                id: "1",
                name: "Starlink 6-1",
                details: nil,
                success: true,
                upcoming: false,
                dateUTC: Date(),
                datePrecision: .hour,
                links: nil,
                rocket: .id("falcon9"),
                launchpad: .populated(
                    LaunchpadSummary(
                        id: "ksc",
                        name: "KSC LC 39A",
                        fullName: "Kennedy Space Center LC 39A",
                        locality: "Cape Canaveral",
                        region: "Florida"
                    )
                )
            )
        )
    }
}
