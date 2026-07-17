import XCTest
@testable import IGBlockCore

final class RouteClassifierTests: XCTestCase {
    func testReelsTabIsRestricted() {
        XCTAssertTrue(RouteClassifier.isRestricted(path: "/reels/"))
    }
    func testExploreTabIsRestricted() {
        XCTAssertTrue(RouteClassifier.isRestricted(path: "/explore/"))
    }
    func testExploreSubPathIsRestricted() {
        XCTAssertTrue(RouteClassifier.isRestricted(path: "/explore/tags/travel/"))
    }
    func testSingleReelPermalinkIsNotRestricted() {
        XCTAssertFalse(RouteClassifier.isRestricted(path: "/reel/CxYzAbC123/"))
    }
    func testPostPermalinkIsNotRestricted() {
        XCTAssertFalse(RouteClassifier.isRestricted(path: "/p/CxYzAbC123/"))
    }
    func testDirectMessagesAreNotRestricted() {
        XCTAssertFalse(RouteClassifier.isRestricted(path: "/direct/inbox/"))
    }
    func testProfilePageIsNotRestricted() {
        XCTAssertFalse(RouteClassifier.isRestricted(path: "/someusername/"))
    }
    func testHomeFeedIsNotRestricted() {
        XCTAssertFalse(RouteClassifier.isRestricted(path: "/"))
    }

    // isPartOfReelsSession: used to keep a user "counted" while browsing individual
    // full-screen reels reached FROM the Reels tab, even if that per-reel view uses a
    // URL segment ("reel") that isn't itself in the base restricted set. This is a
    // broader membership check than isRestricted — it does NOT by itself mean "block
    // this route"; AppState combines it with session state to decide that.
    func testReelsTabIsPartOfReelsSession() {
        XCTAssertTrue(RouteClassifier.isPartOfReelsSession(path: "/reels/"))
    }
    func testExploreTabIsPartOfReelsSession() {
        XCTAssertTrue(RouteClassifier.isPartOfReelsSession(path: "/explore/"))
    }
    func testSingleReelPermalinkIsPartOfReelsSession() {
        XCTAssertTrue(RouteClassifier.isPartOfReelsSession(path: "/reel/CxYzAbC123/"))
    }
    func testDirectMessagesAreNotPartOfReelsSession() {
        XCTAssertFalse(RouteClassifier.isPartOfReelsSession(path: "/direct/inbox/"))
    }
    func testProfilePageIsNotPartOfReelsSession() {
        XCTAssertFalse(RouteClassifier.isPartOfReelsSession(path: "/someusername/"))
    }
    func testHomeFeedIsNotPartOfReelsSession() {
        XCTAssertFalse(RouteClassifier.isPartOfReelsSession(path: "/"))
    }
    func testPostPermalinkIsNotPartOfReelsSession() {
        XCTAssertFalse(RouteClassifier.isPartOfReelsSession(path: "/p/CxYzAbC123/"))
    }
}
