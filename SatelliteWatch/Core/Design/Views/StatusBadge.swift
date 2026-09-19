import SwiftUI

struct StatusBadge: View {
    let status: LaunchStatus

    var body: some View {
        Text(status.title)
            .font(AppFont.captionSemibold)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .foregroundStyle(status.color)
            .background(status.color.opacity(AppColor.badgeFillOpacity), in: Capsule())
            .accessibilityLabel("Launch status \(status.title)")
    }
}

#Preview {
    VStack(spacing: Spacing.sm) {
        StatusBadge(status: .success)
        StatusBadge(status: .failure)
        StatusBadge(status: .upcoming)
        StatusBadge(status: .unknown)
    }
}
