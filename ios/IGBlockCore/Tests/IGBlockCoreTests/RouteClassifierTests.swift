import XCTest
@testable import IGBlockCore

final class RouteClassifierTests: XCTestCase {
    private let bothEnabled: Set<RestrictedSection> = [.reels, .explore]

    func testReelsTabIsRestricted() {
        XCTAssertTrue(RouteClassifier.isRestricted(path: "/reels/", enabledSections: bothEnabled))
    }
    func testExploreTabIsRestricted() {
        XCTAssertTrue(RouteClassifier.isRestricted(path: "/explore/", enabledSections: bothEnabled))
    }
    func testExploreSubPathIsRestricted() {
        XCTAssertTrue(RouteClassifier.isRestricted(path: "/explore/tags/travel/", enabledSections: bothEnabled))
    }
    func testSingleReelPermalinkIsNotRestricted() {
        XCTAssertFalse(RouteClassifier.isRestricted(path: "/reel/CxYzAbC123/", enabledSections: bothEnabled))
    }
    func testPostPermalinkIsNotRestricted() {
        XCTAssertFalse(RouteClassifier.isRestricted(path: "/p/CxYzAbC123/", enabledSections: bothEnabled))
    }
    func testDirectMessagesAreNotRestricted() {
        XCTAssertFalse(RouteClassifier.isRestricted(path: "/direct/inbox/", enabledSections: bothEnabled))
    }
    func testProfilePageIsNotRestricted() {
        XCTAssertFalse(RouteClassifier.isRestricted(path: "/someusername/", enabledSections: bothEnabled))
    }
    func testHomeFeedIsNotRestricted() {
        XCTAssertFalse(RouteClassifier.isRestricted(path: "/", enabledSections: bothEnabled))
    }
    func testReelsTabIsNotRestrictedWhenReelsSectionDisabled() {
        XCTAssertFalse(RouteClassifier.isRestricted(path: "/reels/", enabledSections: [.explore]))
    }
    func testExploreTabIsNotRestrictedWhenExploreSectionDisabled() {
        XCTAssertFalse(RouteClassifier.isRestricted(path: "/explore/", enabledSections: [.reels]))
    }
    func testNothingIsRestrictedWhenNoSectionsEnabled() {
        XCTAssertFalse(RouteClassifier.isRestricted(path: "/reels/", enabledSections: []))
        XCTAssertFalse(RouteClassifier.isRestricted(path: "/explore/", enabledSections: []))
    }

    // isPartOfReelsSession: used to keep a user "counted" while browsing individual
    // full-screen reels reached FROM the Reels tab, even if that per-reel view uses a
    // URL segment ("reel") that isn't itself in the base restricted set. This is a
    // broader membership check than isRestricted — it does NOT by itself mean "block
    // this route"; AppState combines it with session state to decide that.
    func testReelsTabIsPartOfReelsSession() {
        XCTAssertTrue(RouteClassifier.isPartOfReelsSession(path: "/reels/", enabledSections: bothEnabled))
    }
    func testExploreTabIsPartOfReelsSession() {
        XCTAssertTrue(RouteClassifier.isPartOfReelsSession(path: "/explore/", enabledSections: bothEnabled))
    }
    func testSingleReelPermalinkIsPartOfReelsSession() {
        XCTAssertTrue(RouteClassifier.isPartOfReelsSession(path: "/reel/CxYzAbC123/", enabledSections: bothEnabled))
    }
    func testDirectMessagesAreNotPartOfReelsSession() {
        XCTAssertFalse(RouteClassifier.isPartOfReelsSession(path: "/direct/inbox/", enabledSections: bothEnabled))
    }
    func testProfilePageIsNotPartOfReelsSession() {
        XCTAssertFalse(RouteClassifier.isPartOfReelsSession(path: "/someusername/", enabledSections: bothEnabled))
    }
    func testHomeFeedIsNotPartOfReelsSession() {
        XCTAssertFalse(RouteClassifier.isPartOfReelsSession(path: "/", enabledSections: bothEnabled))
    }
    func testPostPermalinkIsNotPartOfReelsSession() {
        XCTAssertFalse(RouteClassifier.isPartOfReelsSession(path: "/p/CxYzAbC123/", enabledSections: bothEnabled))
    }
    func testSingleReelPermalinkIsNotPartOfReelsSessionWhenReelsSectionDisabled() {
        XCTAssertFalse(RouteClassifier.isPartOfReelsSession(path: "/reel/CxYzAbC123/", enabledSections: [.explore]))
    }
    func testExploreTabIsNotPartOfReelsSessionWhenExploreSectionDisabled() {
        XCTAssertFalse(RouteClassifier.isPartOfReelsSession(path: "/explore/", enabledSections: [.reels]))
    }
}
