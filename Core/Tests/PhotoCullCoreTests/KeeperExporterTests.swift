import ImageIO
import XCTest
@testable import PhotoCullCore

final class KeeperExporterTests: XCTestCase {
    func testExportEmbedsRatingInJpegCopy() throws {
        let dir = Fixtures.tempDir()
        let photo = Fixtures.write(
            Fixtures.noiseImage(), to: dir.appendingPathComponent("keep.jpg"))
        let out = dir.appendingPathComponent("keepers")

        let result = try KeeperExporter.exportKeepers([photo], to: out)

        XCTAssertEqual(result.copied, 1)
        XCTAssertEqual(result.embedded, 1)
        XCTAssertEqual(result.sidecars, 0)

        let copy = out.appendingPathComponent("keep.jpg")
        let src = try XCTUnwrap(CGImageSourceCreateWithURL(copy as CFURL, nil))
        let meta = try XCTUnwrap(CGImageSourceCopyMetadataAtIndex(src, 0, nil))
        let tag = try XCTUnwrap(
            CGImageMetadataCopyTagWithPath(meta, nil, "xmp:Rating" as CFString))
        XCTAssertEqual(CGImageMetadataTagCopyValue(tag) as? String, "3")

        // Original untouched: no rating in its header
        let origSrc = try XCTUnwrap(CGImageSourceCreateWithURL(photo as CFURL, nil))
        if let origMeta = CGImageSourceCopyMetadataAtIndex(origSrc, 0, nil) {
            XCTAssertNil(CGImageMetadataCopyTagWithPath(origMeta, nil, "xmp:Rating" as CFString))
        }
    }

    func testRawCopyGetsSidecarNextToIt() throws {
        let dir = Fixtures.tempDir()
        let raw = dir.appendingPathComponent("shot.cr2")
        try Data("fake raw bytes".utf8).write(to: raw)
        let out = dir.appendingPathComponent("keepers")

        let result = try KeeperExporter.exportKeepers([raw], to: out)

        XCTAssertEqual(result.copied, 1)
        XCTAssertEqual(result.sidecars, 1)
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: out.appendingPathComponent("shot.cr2").path))
        let content = try String(
            contentsOf: out.appendingPathComponent("shot.xmp"), encoding: .utf8)
        XCTAssertTrue(content.contains("xmp:Rating=\"3\""))
        XCTAssertTrue(FileManager.default.fileExists(atPath: raw.path), "original untouched")
    }

    func testCollisionSuffixInDestination() throws {
        let dir = Fixtures.tempDir()
        let photo = Fixtures.write(
            Fixtures.noiseImage(), to: dir.appendingPathComponent("a.jpg"))
        let out = dir.appendingPathComponent("keepers")
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        Fixtures.write(Fixtures.noiseImage(seed: 9), to: out.appendingPathComponent("a.jpg"))

        _ = try KeeperExporter.exportKeepers([photo], to: out)

        XCTAssertTrue(FileManager.default.fileExists(
            atPath: out.appendingPathComponent("a-1.jpg").path))
    }
}
