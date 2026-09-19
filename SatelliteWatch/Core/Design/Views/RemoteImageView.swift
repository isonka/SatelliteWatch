import SwiftUI

struct RemoteImageView: View {
    let url: URL?
    var height: CGFloat = 200

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            AppColor.secondaryText.opacity(0.08)
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .accessibilityHidden(url == nil)
    }

    private var placeholder: some View {
        ZStack {
            AppColor.secondaryText.opacity(0.1)
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(AppColor.secondaryText)
        }
        .accessibilityLabel("Image unavailable")
    }
}
