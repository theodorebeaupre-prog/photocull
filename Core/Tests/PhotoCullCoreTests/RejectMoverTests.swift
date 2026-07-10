import XCTest
@testable import PhotoCullCore

final class RejectMoverTests: XCTestCase {
    func testMovesFilesIntoRejectsSubfolder() throws {
        let dir = Fixtures.tempDir()
        let a = Fixtures.write(Fixtures.noiseImage(), to: dir.appendingPathComponent("a.jpg"))
        let b = Fixtures.write(Fixtures.noiseImage(), to: dir.appendingPathComponent("b.jpg"))

        let rejectsDir = try RejectMover.moveRejects([a], from: dir)

        XCTAssertEqual(rejectsDir.lastPathComponent, "_rejects")
        XCTAssertFalse(FileManager.default.fileExists(atPath: a.path))
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: rejectsDir.appendingPathComponent("a.jpg").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: b.path), "b.jpg untouched")
    }

    func testNameCollisionGetsSuffix() throws {
        let dir = Fixtures.tempDir()
        let rejectsDir = dir.appendingPathComponent("_rejects")
        try FileManager.default.createDirectory(at: rejectsDir, withIntermediateDirectories: true)
        Fixtures.write(Fixtures.noiseImage(), to: rejectsDir.appendingPathComponent("a.jpg"))
        let a = Fixtures.write(Fixtures.noiseImage(seed: 9), to: dir.appendingPathComponent("a.jpg"))

        _ = try RejectMover.moveRejects([a], from: dir)

        XCTAssertTrue(FileManager.default.fileExists(
            atPath: rejectsDir.appendingPathComponent("a-1.jpg").path))
    }

    func testCollisionSuffixForExtensionlessFile() throws {
        let dir = Fixtures.tempDir()
        let rejectsDir = dir.appendingPathComponent("_rejects")
        try FileManager.default.createDirectory(at: rejectsDir, withIntermediateDirectories: true)
        try Data("existing".utf8).write(to: rejectsDir.appendingPathComponent("photo"))
        let photo = dir.appendingPathComponent("photo")
        try Data("new".utf8).write(to: photo)

        _ = try RejectMover.moveRejects([photo], from: dir)

        XCTAssertTrue(FileManager.default.fileExists(
            atPath: rejectsDir.appendingPathComponent("photo-1").path))
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: rejectsDir.appendingPathComponent("photo-1.").path))
    }
}
