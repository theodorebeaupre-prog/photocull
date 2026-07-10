import CryptoKit
import Foundation

public struct SessionState: Codable, Equatable {
    public var folder: URL
    /// Keyed by file name (folder-relative) so a renamed/moved folder can still resume.
    public var decisions: [String: CullDecision]

    public init(folder: URL, decisions: [String: CullDecision] = [:]) {
        self.folder = folder
        self.decisions = decisions
    }
}

public final class SessionStore {
    let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public static var `default`: SessionStore {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PhotoCull/Sessions", isDirectory: true)
        return SessionStore(directory: base)
    }

    func fileURL(forFolder folder: URL) -> URL {
        let digest = SHA256.hash(data: Data(folder.standardizedFileURL.path.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined().prefix(16)
        return directory.appendingPathComponent("\(name).json")
    }

    public func save(_ state: SessionState) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(state)
        try data.write(to: fileURL(forFolder: state.folder), options: .atomic)
    }

    public func load(forFolder folder: URL) -> SessionState? {
        guard let data = try? Data(contentsOf: fileURL(forFolder: folder)) else { return nil }
        return try? JSONDecoder().decode(SessionState.self, from: data)
    }
}
