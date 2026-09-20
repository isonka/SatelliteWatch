import SwiftUI

struct LoadingStateView: View {
    var message: String = "Loading…"

    var body: some View {
        ContentUnavailableView {
            ProgressView()
        } description: {
            Text(message)
        }
        .accessibilityIdentifier("loading-state")
    }
}

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    var description: String?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            if let description {
                Text(description)
            }
        }
        .accessibilityIdentifier("empty-state")
    }
}

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("retry-button")
        }
    }
}

#Preview("Loading") {
    LoadingStateView(message: "Loading launches…")
}

#Preview("Empty") {
    EmptyStateView(
        title: "No launches",
        systemImage: "airplane.departure",
        description: "There are no launches to show right now."
    )
}

#Preview("Error") {
    ErrorStateView(message: "SpaceX data is temporarily unavailable. Please try again later.") {}
}
