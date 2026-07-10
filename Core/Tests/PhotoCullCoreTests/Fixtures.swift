import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum Fixtures {
    /// Deterministic RNG so tests never flake.
    struct LCG: RandomNumberGenerator {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }

    static func grayImage(pixels: [UInt8], size: Int) -> CGImage {
        let ctx = CGContext(
            data: nil, width: size, height: size,
            bitsPerComponent: 8, bytesPerRow: size,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )!
        ctx.data!.bindMemory(to: UInt8.self, capacity: size * size)
            .update(from: pixels, count: size * size)
        return ctx.makeImage()!
    }

    static func grayPixels(of image: CGImage) -> [UInt8] {
        let size = image.width
        let ctx = CGContext(
            data: nil, width: size, height: size,
            bitsPerComponent: 8, bytesPerRow: size,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )!
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
        let p = ctx.data!.bindMemory(to: UInt8.self, capacity: size * size)
        return Array(UnsafeBufferPointer(start: p, count: size * size))
    }

    /// High-frequency random noise — maximally "sharp".
    static func noiseImage(size: Int = 256, seed: UInt64 = 42) -> CGImage {
        var rng = LCG(seed: seed)
        var pixels = [UInt8](repeating: 0, count: size * size)
        for i in pixels.indices { pixels[i] = UInt8.random(in: 0...255, using: &rng) }
        return grayImage(pixels: pixels, size: size)
    }

    /// Smooth horizontal gradient — visually very different from noise.
    static func gradientImage(size: Int = 256) -> CGImage {
        var pixels = [UInt8](repeating: 0, count: size * size)
        for y in 0..<size {
            for x in 0..<size {
                pixels[y * size + x] = UInt8((x * 255) / max(1, size - 1))
            }
        }
        return grayImage(pixels: pixels, size: size)
    }

    /// Box blur — turns a sharp image into a blurry one.
    static func blurred(_ image: CGImage, radius: Int = 4) -> CGImage {
        let size = image.width
        let src = grayPixels(of: image)
        var dst = src
        for y in 0..<size {
            for x in 0..<size {
                var sum = 0
                var count = 0
                for dy in -radius...radius {
                    for dx in -radius...radius {
                        let nx = x + dx
                        let ny = y + dy
                        guard nx >= 0, nx < size, ny >= 0, ny < size else { continue }
                        sum += Int(src[ny * size + nx])
                        count += 1
                    }
                }
                dst[y * size + x] = UInt8(sum / count)
            }
        }
        return grayImage(pixels: dst, size: size)
    }

    @discardableResult
    static func write(_ image: CGImage, to url: URL, captureDate: String? = nil) -> URL {
        var props: [CFString: Any] = [:]
        if let captureDate {
            props[kCGImagePropertyExifDictionary] =
                [kCGImagePropertyExifDateTimeOriginal: captureDate]
        }
        let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.jpeg.identifier as CFString, 1, nil
        )!
        CGImageDestinationAddImage(dest, image, props as CFDictionary)
        CGImageDestinationFinalize(dest)
        return url
    }

    static func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("PhotoCullTests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.standardizedFileURL
    }
}
