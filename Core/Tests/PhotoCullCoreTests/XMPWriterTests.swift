import XCTest
@testable import PhotoCullCore

final class XMPWriterTests: XCTestCase {
    func testSidecarXMLMatchesGolden() {
        let expected = """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
                xmlns:xmp="http://ns.adobe.com/xap/1.0/"
                xmp:Rating="3"/>
          </rdf:RDF>
        </x:xmpmeta>
        """
        XCTAssertEqual(XMPWriter.sidecarXML(for: .keep), expected)
    }

    func testRatingsPerDecision() {
        XCTAssertTrue(XMPWriter.sidecarXML(for: .keep).contains("xmp:Rating=\"3\""))
        XCTAssertTrue(XMPWriter.sidecarXML(for: .reject).contains("xmp:Rating=\"-1\""))
        XCTAssertTrue(XMPWriter.sidecarXML(for: .undecided).contains("xmp:Rating=\"0\""))
    }

    func testWritesSidecarNextToPhoto() throws {
        let dir = Fixtures.tempDir()
        let photo = Fixtures.write(
            Fixtures.noiseImage(), to: dir.appendingPathComponent("IMG_0001.jpg"))
        let sidecar = try XMPWriter.writeSidecar(for: photo, decision: .reject)
        XCTAssertEqual(sidecar.lastPathComponent, "IMG_0001.xmp")
        XCTAssertEqual(sidecar.deletingLastPathComponent(), dir)
        let content = try String(contentsOf: sidecar, encoding: .utf8)
        XCTAssertTrue(content.contains("xmp:Rating=\"-1\""))
    }
}
