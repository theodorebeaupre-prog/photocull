import CoreGraphics
import Foundation
import ImageIO

public struct AnalyzedPhoto: Sendable {
    public let analysis: PhotoAnalysis
    public let featurePrint: FeaturePrint?

    public init(analysis: PhotoAnalysis, featurePrint: FeaturePrint?) {
        self.analysis = analysis
        self.featurePrint = featurePrint
    }
}

public struct CullEngine: Sendable {
    public let maxConcurrency: Int

    public init(maxConcurrency: Int = 4) {
        self.maxConcurrency = max(1, maxConcurrency)
    }

    public static let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "heic", "png", "tif", "tiff",
        "raf", "cr2", "cr3", "nef", "arw", "dng", "orf", "rw2"
    ]

    public func imageURLs(in folder: URL) throws -> [URL] {
        try FileManager.default
            .contentsOfDirectory(at: folder, includingPropertiesForKeys: nil,
                                 options: [.skipsHiddenFiles])
            .filter { Self.supportedExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Bounded-concurrency analysis. Yields results as they complete so the UI
    /// fills progressively. An unreadable file yields analysisFailed — never a crash.
    public func analyzeFolder(_ folder: URL) -> AsyncStream<AnalyzedPhoto> {
        AsyncStream { continuation in
            let urls = (try? imageURLs(in: folder)) ?? []
            let concurrency = maxConcurrency
            let task = Task {
                await withTaskGroup(of: AnalyzedPhoto.self) { group in
                    var iterator = urls.makeIterator()
                    func addNext() {
                        if let url = iterator.next() {
                            group.addTask { Self.analyze(url) }
                        }
                    }
                    for _ in 0..<concurrency { addNext() }
                    for await result in group {
                        continuation.yield(result)
                        addNext()
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    static func analyze(_ url: URL) -> AnalyzedPhoto {
        // Decode once at analysis resolution; RAW goes through ImageIO like JPEG.
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(src, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceThumbnailMaxPixelSize: 1024
              ] as CFDictionary)
        else {
            return AnalyzedPhoto(
                analysis: PhotoAnalysis(id: url, analysisFailed: true),
                featurePrint: nil)
        }
        var analysis = PhotoAnalysis(id: url)
        analysis.sharpness = SharpnessAnalyzer.laplacianVariance(of: image)
        analysis.closedEyesProbability = (try? FaceAnalyzer.closedEyesProbability(in: image)) ?? nil
        analysis.captureDate = ExifReader.captureDate(of: url)
        let featurePrint = try? FeaturePrint.compute(for: image)
        return AnalyzedPhoto(analysis: analysis, featurePrint: featurePrint)
    }
}
