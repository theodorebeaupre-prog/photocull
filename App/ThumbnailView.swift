import CoreGraphics
import ImageIO
import SwiftUI

enum ThumbnailLoader {
    static func thumbnail(for url: URL, maxPixel: Int) -> CGImage? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(src, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ] as CFDictionary)
    }
}

struct ThumbnailView: View {
    let url: URL
    var maxPixel: Int = 384
    @State private var image: CGImage?

    var body: some View {
        Group {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle().fill(.quaternary)
            }
        }
        .task(id: url) {
            let target = url
            let size = maxPixel
            image = await Task.detached(priority: .userInitiated) {
                ThumbnailLoader.thumbnail(for: target, maxPixel: size)
            }.value
        }
    }
}

struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.85), in: Capsule())
            .foregroundStyle(.white)
    }
}
