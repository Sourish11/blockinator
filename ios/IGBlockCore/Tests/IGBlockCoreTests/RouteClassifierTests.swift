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
}
