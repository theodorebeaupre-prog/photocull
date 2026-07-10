import XCTest
@testable import PhotoCullCore

final class SessionStoreTests: XCTestCase {
    func testSaveLoadRoundTrip() throws {
        let store = SessionStore(directory: Fixtures.tempDir())
        let folder = URL(fileURLWithPath: "/photos/wedding")
        let state = SessionState(
            folder: folder,
            decisions: ["a.jpg": .keep, "b.jpg": .reject])
        try store.save(state)
        XCTAssertEqual(store.load(forFolder: folder), state)
    }

    func testLoadUnknownFolderReturnsNil() {
        let store = SessionStore(directory: Fixtures.tempDir())
        XCTAssertNil(store.load(forFolder: URL(fileURLWithPath: "/photos/nope")))
    }

    func testDistinctFoldersDoNotCollide() throws {
        let store = SessionStore(directory: Fixtures.tempDir())
        let f1 = URL(fileURLWithPath: "/photos/one")
        let f2 = URL(fileURLWithPath: "/photos/two")
        try store.save(SessionState(folder: f1, decisions: ["a.jpg": .keep]))
        try store.save(SessionState(folder: f2, decisions: ["a.jpg": .reject]))
        XCTAssertEqual(store.load(forFolder: f1)?.decisions["a.jpg"], .keep)
        XCTAssertEqual(store.load(forFolder: f2)?.decisions["a.jpg"], .reject)
    }
}
