import Foundation
import ImageIO

/// Exports keeper photos as COPIES for import into Lightroom (cloud).
/// Lightroom cloud ignores sidecar ratings and only reads metadata embedded
/// in the file itself, so non-RAW copies get xmp:Rating merged into their
/// header (lossless — pixels are not re-encoded). RAW copies get a .xmp
/// sidecar next to them. Originals are never touched.
public enum KeeperExporter {
    public struct ExportResult: Equatable, Sendable {
        public var copied = 0
        public var embedded = 0
        public var sidecars = 0
        public init() {}
    }

    static let rawExtensions: Set<String> = [
        "raf", "cr2", "cr3", "nef", "arw", "dng", "orf", "rw2"
    ]

    @discardableResult
    public static func exportKeepers(
        _ urls: [URL], to destination: URL, rating: Int = 3
    ) throws -> ExportResult {
        let fm = FileManager.default
        try fm.createDirectory(at: destination, withIntermediateDirectories: true)
        var result = ExportResult()
        for url in urls.sorted(by: { $0.path < $1.path }) {
            let dest = availableDestination(for: url, in: destination)
            if rawExtensions.contains(url.pathExtension.lowercased()) {
                try fm.copyItem(at: url, to: dest)
                let sidecar = dest.deletingPathExtension().appendingPathExtension("xmp")
                try XMPWriter.sidecarXML(for: .keep)
                    .write(to: sidecar, atomically: true, encoding: .utf8)
                result.sidecars += 1
            } else if copyEmbeddingRating(from: url, to: dest, rating: rating) {
                result.embedded += 1
            } else {
                // Embedding failed (unreadable/unsupported format): plain copy.
                try fm.copyItem(at: url, to: dest)
            }
            result.copied += 1
        }
        return result
    }

    static func availableDestination(for url: URL, in folder: URL) -> URL {
        let fm = FileManager.default
        var dest = folder.appendingPathComponent(url.lastPathComponent)
        var counter = 1
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        while fm.fileExists(atPath: dest.path) {
            let suffixed = ext.isEmpty ? "\(base)-\(counter)" : "\(base)-\(counter).\(ext)"
            dest = folder.appendingPathComponent(suffixed)
            counter += 1
        }
        return dest
    }

    /// Lossless copy with xmp:Rating merged into the header. Returns false
    /// when the source can't be read or the format doesn't support metadata.
    static func copyEmbeddingRating(from source: URL, to dest: URL, rating: Int) -> Bool {
        guard let src = CGImageSourceCreateWithURL(source as CFURL, nil),
              let type = CGImageSourceGetType(src),
              let dst = CGImageDestinationCreateWithURL(dest as CFURL, type, 1, nil)
        else { return false }

        let xmpNamespace = "http://ns.adobe.com/xap/1.0/" as CFString
        let meta = CGImageMetadataCreateMutable()
        guard CGImageMetadataRegisterNamespaceForPrefix(
                  meta, xmpNamespace, "xmp" as CFString, nil),
              let tag = CGImageMetadataTagCreate(
                  xmpNamespace, "xmp" as CFString, "Rating" as CFString,
                  .string, String(rating) as CFString),
              CGImageMetadataSetTagWithPath(meta, nil, "xmp:Rating" as CFString, tag)
        else { return false }

        let options: [CFString: Any] = [
            kCGImageDestinationMergeMetadata: true,
            kCGImageDestinationMetadata: meta
        ]
        return CGImageDestinationCopyImageSource(dst, src, options as CFDictionary, nil)
    }
}
