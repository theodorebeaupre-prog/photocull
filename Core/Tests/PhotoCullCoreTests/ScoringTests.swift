import XCTest
@testable import PhotoCullCore

final class ScoringTests: XCTestCase {
    private func analysis(
        _ name: String, sharpness: Double?, closedEyes: Double? = nil, failed: Bool = false
    ) -> PhotoAnalysis {
        PhotoAnalysis(
            id: URL(fileURLWithPath: "/photos/\(name)"),
            sharpness: sharpness, closedEyesProbability: closedEyes,
            analysisFailed: failed)
    }

    func testSharpnessScoreNormalization() {
        XCTAssertEqual(Scoring.sharpnessScore(nil), 0.5, accuracy: 0.001)
        XCTAssertEqual(Scoring.sharpnessScore(0), 0.0, accuracy: 0.001)
        XCTAssertEqual(Scoring.sharpnessScore(100), 0.5, accuracy: 0.001)
        XCTAssertEqual(Scoring.sharpnessScore(200), 1.0, accuracy: 0.001)
        XCTAssertEqual(Scoring.sharpnessScore(9999), 1.0, accuracy: 0.001)
    }

    func testFailedAnalysisScoresZero() {
        XCTAssertEqual(Scoring.overallScore(analysis("x.jpg", sharpness: 500, failed: true)), 0)
    }

    func testClosedEyesPenalizesScore() {
        let openEyes = Scoring.overallScore(analysis("a.jpg", sharpness: 200, closedEyes: 0))
        let closedEyes = Scoring.overallScore(analysis("b.jpg", sharpness: 200, closedEyes: 1))
        XCTAssertGreaterThan(openEyes, closedEyes)
        XCTAssertEqual(closedEyes, 0.4, accuracy: 0.001)
    }

    func testSuggestKeeperPicksSharpestOpenEyes() {
        let group = [
            analysis("blurry.jpg", sharpness: 10),
            analysis("winner.jpg", sharpness: 250, closedEyes: 0),
            analysis("closed.jpg", sharpness: 250, closedEyes: 0.9)
        ]
        XCTAssertEqual(
            Scoring.suggestKeeper(in: group),
            URL(fileURLWithPath: "/photos/winner.jpg"))
    }

    func testSuggestKeeperEmptyGroupIsNil() {
        XCTAssertNil(Scoring.suggestKeeper(in: []))
    }
}
