import CoreGraphics

public enum SharpnessAnalyzer {
    /// Variance of the Laplacian on a grayscale, downscaled copy of the image.
    /// Higher = sharper. Blur suppresses high frequencies, collapsing the variance.
    public static func laplacianVariance(of image: CGImage, maxDimension: Int = 256) -> Double {
        let scale = min(1.0, Double(maxDimension) / Double(max(image.width, image.height)))
        let w = max(3, Int(Double(image.width) * scale))
        let h = max(3, Int(Double(image.height) * scale))
        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return 0 }
        ctx.interpolationQuality = .medium
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let data = ctx.data else { return 0 }
        let p = data.bindMemory(to: UInt8.self, capacity: w * h)

        var values = [Double]()
        values.reserveCapacity((w - 2) * (h - 2))
        for y in 1..<(h - 1) {
            for x in 1..<(w - 1) {
                let c = 4 * Double(p[y * w + x])
                let lap = c
                    - Double(p[y * w + x - 1]) - Double(p[y * w + x + 1])
                    - Double(p[(y - 1) * w + x]) - Double(p[(y + 1) * w + x])
                values.append(lap)
            }
        }
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        return values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
    }
}
