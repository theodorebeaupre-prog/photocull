import XCTest
@testable import PhotoCullCore

final class SharpnessTests: XCTestCase {
    func testSharpImageScoresHigherThanBlurred() {
        let sharp = Fixtures.noiseImage()
        let blurry = Fixtures.blurred(sharp, radius: 6)
        let sharpVar = SharpnessAnalyzer.laplacianVariance(of: sharp)
        let blurryVar = SharpnessAnalyzer.laplacianVariance(of: blurry)
        XCTAssertGreaterThan(sharpVar, blurryVar * 2,
            "sharp=\(sharpVar) blurry=\(blurryVar)")
    }

    func testFlatImageHasNearZeroVariance() {
        let flat = Fixtures.grayImage(
            pixels: [UInt8](repeating: 128, count: 64 * 64), size: 64)
        XCTAssertLessThan(SharpnessAnalyzer.laplacianVariance(of: flat), 1.0)
    }
}
