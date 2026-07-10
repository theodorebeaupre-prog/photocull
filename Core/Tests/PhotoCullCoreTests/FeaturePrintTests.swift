import XCTest
@testable import PhotoCullCore

final class FeaturePrintTests: XCTestCase {
    func testIdenticalImagesAreCloserThanDifferentImages() throws {
        let noise = Fixtures.noiseImage()
        let a = try FeaturePrint.compute(for: noise)
        let b = try FeaturePrint.compute(for: noise)
        let c = try FeaturePrint.compute(for: Fixtures.gradientImage())
        let same = try a.distance(to: b)
        let different = try a.distance(to: c)
        XCTAssertLessThan(same, 0.01, "identical images should have ~0 distance")
        XCTAssertGreaterThan(different, same)
    }
}
