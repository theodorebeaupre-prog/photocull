import XCTest
@testable import PhotoCullCore

final class ExifReaderTests: XCTestCase {
    func testReadsCaptureDateFromExif() {
        let dir = Fixtures.tempDir()
        let url = Fixtures.write(
            Fixtures.noiseImage(),
            to: dir.appendingPathComponent("dated.jpg"),
            captureDate: "2026:07:09 10:30:00"
        )
        let date = ExifReader.captureDate(of: url)
        XCTAssertNotNil(date)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let c = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date!)
        XCTAssertEqual([c.year, c.month, c.day, c.hour, c.minute], [2026, 7, 9, 10, 30])
    }

    func testReturnsNilWithoutExifDate() {
        let dir = Fixtures.tempDir()
        let url = Fixtures.write(
            Fixtures.noiseImage(), to: dir.appendingPathComponent("undated.jpg"))
        XCTAssertNil(ExifReader.captureDate(of: url))
    }

    func testReturnsNilForMissingFile() {
        XCTAssertNil(ExifReader.captureDate(of: URL(fileURLWithPath: "/nonexistent.jpg")))
    }
}
