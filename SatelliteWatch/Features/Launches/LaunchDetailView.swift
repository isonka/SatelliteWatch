import SwiftUI

struct LaunchDetailView: View {
    let launch: Launch

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                RemoteImageView(url: launch.patchImageURL, height: 220)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(launch.name)
                            .font(AppFont.title)
                            .foregroundStyle(AppColor.primaryText)
                        Spacer(minLength: Spacing.sm)
                        StatusBadge(status: launch.status)
                    }

                    labeledRow("Launch site", launch.launchSiteName)
                    labeledRow(
                        "Date",
                        DateFormatting.display(date: launch.dateUTC, precision: launch.datePrecision)
                    )

                    Text(descriptionText)
                        .font(AppFont.body)
                        .foregroundStyle(hasDescription ? AppColor.primaryText : AppColor.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, Spacing.lg)

                if let webcastURL = launch.webcastURL {
                    Link(destination: webcastURL) {
                        Label("Watch launch", systemImage: "play.rectangle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, Spacing.lg)
                    .accessibilityIdentifier("watch-launch-link")
                }

                if let rocket = launch.populatedRocket {
                    NavigationLink(value: rocket) {
                        RocketCardView(rocket: rocket)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Spacing.lg)
                } else {
                    Text("Rocket details unavailable.")
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColor.secondaryText)
                        .padding(.horizontal, Spacing.lg)
                }
            }
            .padding(.bottom, Spacing.xl)
        }
        .navigationTitle("Launch")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Rocket.self) { rocket in
            RocketDetailView(rocket: rocket)
        }
    }

    private var hasDescription: Bool {
        !(launch.details?.isEmpty ?? true)
    }

    private var descriptionText: String {
        hasDescription ? launch.details! : "No description available."
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs / 2) {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryText)
            Text(value)
                .font(AppFont.subheadline)
                .foregroundStyle(AppColor.primaryText)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        LaunchDetailView(launch: MockSpaceXService.previewLaunches[0])
    }
}
#endif
