import SwiftUI
import UIKit

struct RemoteImageView: View {
    let url: URL?
    var height: CGFloat = 200

    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?
    @State private var didFail = false

    var body: some View {
        // Color.clear owns layout. Overlay draws the bitmap so a wide photo
        // cannot widen a ScrollView and clip the rest of the screen.
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay {
                imageContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
            .clipped()
            .accessibilityHidden(url == nil)
            .task(id: url) {
                image = nil
                didFail = false
                guard let url else { return }
                let maxPixelSize = max(1, height * displayScale)
                if let loaded = await RemoteImageLoader.shared.image(
                    from: url,
                    maxPixelSize: maxPixelSize
                ) {
                    image = loaded
                } else if !Task.isCancelled {
                    didFail = true
                }
            }
    }

    @ViewBuilder
    private var imageContent: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if url == nil || didFail {
            placeholder
        } else {
            ZStack {
                AppColor.secondaryText.opacity(0.08)
                ProgressView()
            }
        }
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
