import SwiftUI

struct LaunchDetailView: View {
    let launch: Launch
    let service: any ServiceProtocol

    @State private var rocketViewModel: LaunchRocketViewModel

    init(launch: Launch, service: any ServiceProtocol) {
        self.launch = launch
        self.service = service
        _rocketViewModel = State(initialValue: LaunchRocketViewModel(launch: launch))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                RemoteImageView(url: launch.patchImageURL, height: 220)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(launch.name)
                            .font(AppFont.title)
                            .foregroundStyle(AppColor.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: Spacing.sm)
                        StatusBadge(status: launch.status)
                            .fixedSize()
                    }

                    labeledRow("Launch site", launch.launchSiteName)
                    labeledRow(
                        "Date",
                        DateFormatting.display(date: launch.dateUTC, precision: launch.datePrecision)
                    )

                    Text(descriptionText ?? "No description available.")
                        .font(AppFont.body)
                        .foregroundStyle(descriptionText == nil ? AppColor.secondaryText : AppColor.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
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

                rocketSection
                    .padding(.horizontal, Spacing.lg)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .containerRelativeFrame(.horizontal, alignment: .leading)
            .padding(.bottom, Spacing.xl)
        }
        .navigationTitle("Launch")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("launch-detail-\(launch.id)")
        .task {
            await rocketViewModel.loadIfNeeded(using: service)
        }
    }

    @ViewBuilder
    private var rocketSection: some View {
        switch rocketViewModel.state {
        case .loaded(let rocket):
            NavigationLink(value: rocket) {
                RocketCardView(rocket: rocket)
            }
            .buttonStyle(.plain)

        case .unavailable:
            Label(
                "This data source does not provide rocket details for this launch.",
                systemImage: "questionmark.circle"
            )
            .font(AppFont.subheadline)
            .foregroundStyle(AppColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md))
            .accessibilityIdentifier("rocket-card-unavailable")

        case .idle, .loading:
            HStack(spacing: Spacing.md) {
                ProgressView()
                Text("Loading rocket…")
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md))
            .accessibilityIdentifier("rocket-card-loading")

        case .failed(let message):
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(AppFont.subheadline)
                    .foregroundStyle(AppColor.danger)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Retry") {
                    Task { await rocketViewModel.retry() }
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("rocket-card-retry")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md))
        }
    }

    /// Non-empty launch details, or nil when the payload carries none.
    private var descriptionText: String? {
        guard let details = launch.details, !details.isEmpty else { return nil }
        return details
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
        LaunchDetailView(
            launch: MockSpaceXService.previewLaunches[0],
            service: MockSpaceXService()
        )
    }
}
#endif
