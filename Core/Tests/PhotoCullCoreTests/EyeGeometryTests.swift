import XCTest
@testable import PhotoCullCore

final class EyeGeometryTests: XCTestCase {
    /// Ellipse-ish open eye: tall relative to width.
    private let openEye = [
        CGPoint(x: 0.0, y: 0.5), CGPoint(x: 0.25, y: 0.8), CGPoint(x: 0.75, y: 0.8),
        CGPoint(x: 1.0, y: 0.5), CGPoint(x: 0.75, y: 0.2), CGPoint(x: 0.25, y: 0.2)
    ]
    /// Nearly flat line: closed eye.
    private let closedEye = [
        CGPoint(x: 0.0, y: 0.50), CGPoint(x: 0.25, y: 0.52), CGPoint(x: 0.75, y: 0.52),
        CGPoint(x: 1.0, y: 0.50), CGPoint(x: 0.75, y: 0.48), CGPoint(x: 0.25, y: 0.48)
    ]

    func testOpenEyeHasHigherOpenness() {
        let open = EyeGeometry.opennessRatio(openEye)
        let closed = EyeGeometry.opennessRatio(closedEye)
        XCTAssertGreaterThan(open, 0.3)
        XCTAssertLessThan(closed, 0.1)
    }

    func testClosedProbabilityMapping() {
        XCTAssertEqual(EyeGeometry.closedProbability(openness: 0.0), 1.0, accuracy: 0.001)
        XCTAssertEqual(EyeGeometry.closedProbability(openness: 0.3), 0.0, accuracy: 0.001)
        XCTAssertEqual(EyeGeometry.closedProbability(openness: 0.15), 0.5, accuracy: 0.001)
        XCTAssertEqual(EyeGeometry.closedProbability(openness: 1.0), 0.0, accuracy: 0.001)
    }

    func testDegenerateInputIsSafe() {
        XCTAssertEqual(EyeGeometry.opennessRatio([]), 0)
        XCTAssertEqual(EyeGeometry.opennessRatio([CGPoint(x: 1, y: 1)]), 0)
    }

    func testNoiseImageHasNoFace() throws {
        XCTAssertNil(try FaceAnalyzer.closedEyesProbability(in: Fixtures.noiseImage()))
    }
}
