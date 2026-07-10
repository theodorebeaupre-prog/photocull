import XCTest
@testable import PhotoCullCore

final class ModelsTests: XCTestCase {
    func testPhotoAnalysisCodableRoundTrip() throws {
        let url = URL(fileURLWithPath: "/tmp/a.jpg")
        let original = PhotoAnalysis(
            id: url,
            sharpness: 123.4,
            closedEyesProbability: 0.8,
            captureDate: Date(timeIntervalSince1970: 1_700_000_000),
            analysisFailed: false
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PhotoAnalysis.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testDefaultsAreNilAndNotFailed() {
        let a = PhotoAnalysis(id: URL(fileURLWithPath: "/tmp/b.jpg"))
        XCTAssertNil(a.sharpness)
        XCTAssertNil(a.closedEyesProbability)
        XCTAssertNil(a.captureDate)
        XCTAssertFalse(a.analysisFailed)
    }

    func testCullDecisionRawValues() {
        XCTAssertEqual(CullDecision.keep.rawValue, "keep")
        XCTAssertEqual(CullDecision.reject.rawValue, "reject")
        XCTAssertEqual(CullDecision.undecided.rawValue, "undecided")
    }
}
