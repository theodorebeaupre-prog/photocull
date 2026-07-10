import Foundation

public enum XMPWriter {
    /// Lightroom Classic reads xmp:Rating from sidecars.
    /// keep → 3 stars; reject → -1 (Adobe Bridge's reject convention); undecided → 0.
    public static func sidecarXML(for decision: CullDecision) -> String {
        let rating: Int
        switch decision {
        case .keep: rating = 3
        case .reject: rating = -1
        case .undecided: rating = 0
        }
        return sidecarXML(rating: rating)
    }

    public static func sidecarXML(rating: Int) -> String {
        return """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
                xmlns:xmp="http://ns.adobe.com/xap/1.0/"
                xmp:Rating="\(rating)"/>
          </rdf:RDF>
        </x:xmpmeta>
        """
    }

    /// Writes `<basename>.xmp` next to the photo. Never overwrites an existing
    /// sidecar (it may hold Lightroom edits) — returns nil when skipped.
    @discardableResult
    public static func writeSidecar(for photoURL: URL, decision: CullDecision) throws -> URL? {
        let sidecar = photoURL.deletingPathExtension().appendingPathExtension("xmp")
        guard !FileManager.default.fileExists(atPath: sidecar.path) else { return nil }
        try sidecarXML(for: decision).write(to: sidecar, atomically: true, encoding: .utf8)
        return sidecar
    }
}
