import XCTest
@testable import PhotoCullCore

final class GroupingTests: XCTestCase {
    private func url(_ name: String) -> URL { URL(fileURLWithPath: "/photos/\(name)") }
    private func item(_ name: String, secondsAfterEpoch: TimeInterval?) -> GroupingItem {
        GroupingItem(
            id: url(name),
            captureDate: secondsAfterEpoch.map { Date(timeIntervalSince1970: $0) })
    }

    func testBurstWithinWindowAndSimilarFormsOneGroup() {
        let items = [
            item("a.jpg", secondsAfterEpoch: 0),
            item("b.jpg", secondsAfterEpoch: 1),
            item("c.jpg", secondsAfterEpoch: 2)
        ]
        let groups = Grouping.groupPhotos(items) { _, _ in 0.1 }
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].members, [url("a.jpg"), url("b.jpg"), url("c.jpg")])
    }

    func testTimeGapSplitsGroups() {
        let items = [
            item("a.jpg", secondsAfterEpoch: 0),
            item("b.jpg", secondsAfterEpoch: 100)
        ]
        let groups = Grouping.groupPhotos(items) { _, _ in 0.1 }
        XCTAssertEqual(groups.count, 2)
    }

    func testVisualDistanceSplitsGroups() {
        let items = [
            item("a.jpg", secondsAfterEpoch: 0),
            item("b.jpg", secondsAfterEpoch: 1)
        ]
        let groups = Grouping.groupPhotos(items) { _, _ in 5.0 }
        XCTAssertEqual(groups.count, 2)
    }

    func testNilDistanceMeansNotSimilar() {
        let items = [
            item("a.jpg", secondsAfterEpoch: 0),
            item("b.jpg", secondsAfterEpoch: 1)
        ]
        let groups = Grouping.groupPhotos(items) { _, _ in nil }
        XCTAssertEqual(groups.count, 2)
    }

    func testUndatedPhotosBecomeSingletons() {
        let items = [
            item("a.jpg", secondsAfterEpoch: 0),
            item("nodate.jpg", secondsAfterEpoch: nil)
        ]
        let groups = Grouping.groupPhotos(items) { _, _ in 0.1 }
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[1].members, [url("nodate.jpg")])
    }

    func testUnsortedInputIsSortedChronologically() {
        let items = [
            item("late.jpg", secondsAfterEpoch: 1),
            item("early.jpg", secondsAfterEpoch: 0)
        ]
        let groups = Grouping.groupPhotos(items) { _, _ in 0.1 }
        XCTAssertEqual(groups[0].members.first, url("early.jpg"))
    }

    func testDistanceIsMeasuredAgainstGroupAnchor() {
        // a~b similar, b~c similar, but a~c dissimilar.
        // Membership is gated on the anchor (a), so c must start a new group.
        let items = [
            item("a.jpg", secondsAfterEpoch: 0),
            item("b.jpg", secondsAfterEpoch: 1),
            item("c.jpg", secondsAfterEpoch: 2)
        ]
        let groups = Grouping.groupPhotos(items) { lhs, rhs in
            if lhs == url("a.jpg") && rhs == url("c.jpg") { return 5.0 }
            return 0.1
        }
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0].members, [url("a.jpg"), url("b.jpg")])
        XCTAssertEqual(groups[1].members, [url("c.jpg")])
    }
}
