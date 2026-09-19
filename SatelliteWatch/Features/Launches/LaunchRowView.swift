import SwiftUI

struct LaunchRowView: View {
    let launch: Launch

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(launch.name)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.primaryText)
                    .lineLimit(2)
                Spacer(minLength: Spacing.sm)
                StatusBadge(status: launch.status)
            }

            Text(launch.launchSiteName)
                .font(AppFont.subheadline)
                .foregroundStyle(AppColor.secondaryText)
                .lineLimit(2)

            Text(DateFormatting.display(date: launch.dateUTC, precision: launch.datePrecision))
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryText)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
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
