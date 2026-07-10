import XCTest
@testable import PhotoCullCore

final class CullEngineTests: XCTestCase {
    func testAnalyzeFolderYieldsAllImagesAndFlagsBrokenOnes() async throws {
        let dir = Fixtures.tempDir()
        Fixtures.write(
            Fixtures.noiseImage(),
            to: dir.appendingPathComponent("a.jpg"),
            captureDate: "2026:07:09 10:00:00")
        Fixtures.write(
            Fixtures.noiseImage(seed: 7),
            to: dir.appendingPathComponent("b.jpg"))
        try Data("not an image".utf8).write(to: dir.appendingPathComponent("broken.jpg"))
        try Data("ignore me".utf8).write(to: dir.appendingPathComponent("notes.txt"))

        var results: [AnalyzedPhoto] = []
        for await item in CullEngine(maxConcurrency: 2).analyzeFolder(dir) {
            results.append(item)
        }

        XCTAssertEqual(results.count, 3, "txt file must be excluded")

        let broken = results.first { $0.analysis.id.lastPathComponent == "broken.jpg" }
        XCTAssertEqual(broken?.analysis.analysisFailed, true)
        XCTAssertNil(broken?.featurePrint)

        let a = results.first { $0.analysis.id.lastPathComponent == "a.jpg" }
        XCTAssertEqual(a?.analysis.analysisFailed, false)
        XCTAssertNotNil(a?.analysis.sharpness)
        XCTAssertNotNil(a?.analysis.captureDate)
        XCTAssertNotNil(a?.featurePrint)
    }

    func testImageURLsSortedAndFiltered() throws {
        let dir = Fixtures.tempDir()
        Fixtures.write(Fixtures.noiseImage(), to: dir.appendingPathComponent("z.jpg"))
        Fixtures.write(Fixtures.noiseImage(), to: dir.appendingPathComponent("a.jpg"))
        try Data().write(to: dir.appendingPathComponent("skip.txt"))
        let urls = try CullEngine().imageURLs(in: dir)
        XCTAssertEqual(urls.map(\.lastPathComponent), ["a.jpg", "z.jpg"])
    }
}
