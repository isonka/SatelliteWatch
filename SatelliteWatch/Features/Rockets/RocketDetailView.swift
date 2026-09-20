import SwiftUI

struct RocketDetailView: View {
    let rocket: Rocket

    @Environment(LaunchesViewModel.self) private var launchesViewModel

    var body: some View {
        List {
            Section {
                RemoteImageView(url: rocket.primaryImageURL, height: 220)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(rocket.name)
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    labeledRow("Type", rocket.type ?? "Unknown")
                    labeledRow("Status", activeText)
                    labeledRow("Engines", rocket.enginesDisplayText)

                    Text(descriptionText ?? "No description available.")
                        .font(AppFont.body)
                        .foregroundStyle(descriptionText == nil ? AppColor.secondaryText : AppColor.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .listRowSeparator(.hidden)
            }

            Section("From loaded launches") {
                if matchingLaunches.isEmpty {
                    Text("No launches from the current list use this rocket.")
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("rocket-launches-empty")
                } else {
                    ForEach(matchingLaunches) { launch in
                        NavigationLink(value: launch) {
                            LaunchRowView(launch: launch)
                        }
                        .accessibilityIdentifier("rocket-launch-row-\(launch.id)")
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Rocket")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("rocket-detail-\(rocket.id)")
        .navigationDestination(for: Launch.self) { launch in
            LaunchDetailView(launch: launch)
        }
    }

    private var matchingLaunches: [Launch] {
        rocket.launches(from: launchesViewModel.items)
    }

    /// Non-empty rocket description, or nil when the payload carries none.
    private var descriptionText: String? {
        guard let description = rocket.description, !description.isEmpty else { return nil }
        return description
    }

    private var activeText: String {
        guard let active = rocket.active else { return "Unknown" }
        return active ? "Active" : "Inactive"
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
    let launchesViewModel = LaunchesViewModel.preview(launches: MockSpaceXService.previewLaunches)

    return NavigationStack {
        RocketDetailView(rocket: MockSpaceXService.previewRocket)
    }
    .environment(AppDependencies.preview)
    .environment(launchesViewModel)
}
#endif
