import Foundation

public enum RejectMover {
    /// Moves (never deletes) rejected photos into `folder/_rejects/`.
    @discardableResult
    public static func moveRejects(_ urls: [URL], from folder: URL) throws -> URL {
        let fm = FileManager.default
        let rejectsDir = folder.appendingPathComponent("_rejects", isDirectory: true)
        try fm.createDirectory(at: rejectsDir, withIntermediateDirectories: true)
        for url in urls {
            var dest = rejectsDir.appendingPathComponent(url.lastPathComponent)
            var counter = 1
            let base = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension
            while fm.fileExists(atPath: dest.path) {
                let suffixed = ext.isEmpty ? "\(base)-\(counter)" : "\(base)-\(counter).\(ext)"
                dest = rejectsDir.appendingPathComponent(suffixed)
                counter += 1
            }
            try fm.moveItem(at: url, to: dest)
        }
        return rejectsDir
    }
}
