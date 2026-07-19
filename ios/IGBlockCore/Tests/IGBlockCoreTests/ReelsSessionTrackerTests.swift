import XCTest
@testable import IGBlockCore

final class ReelsSessionTrackerTests: XCTestCase {
    private let bothEnabled: Set<RestrictedSection> = [.reels, .explore]

    func testEnteringReelsTabDirectlyIsRestrictedImmediately() {
        var tracker = ReelsSessionTracker()
        XCTAssertTrue(tracker.update(path: "/reels/", enabledSections: bothEnabled))
    }

    func testEnteringExploreTabDirectlyIsRestrictedImmediately() {
        var tracker = ReelsSessionTracker()
        XCTAssertTrue(tracker.update(path: "/explore/", enabledSections: bothEnabled))
    }

    func testFirstColdReelIsExempt() {
        var tracker = ReelsSessionTracker()
        XCTAssertFalse(tracker.update(path: "/reel/A/", enabledSections: bothEnabled))
    }

    func testSameColdReelPathRepeatedStaysExempt() {
        var tracker = ReelsSessionTracker()
        XCTAssertFalse(tracker.update(path: "/reel/A/", enabledSections: bothEnabled))
        XCTAssertFalse(tracker.update(path: "/reel/A/", enabledSections: bothEnabled))
    }

    func testSwipingToASecondDifferentReelStartsCounting() {
        var tracker = ReelsSessionTracker()
        XCTAssertFalse(tracker.update(path: "/reel/A/", enabledSections: bothEnabled))
        XCTAssertTrue(tracker.update(path: "/reel/B/", enabledSections: bothEnabled))
    }

    func testThirdReelStaysCountedOnceSessionStarted() {
        var tracker = ReelsSessionTracker()
        XCTAssertFalse(tracker.update(path: "/reel/A/", enabledSections: bothEnabled))
        XCTAssertTrue(tracker.update(path: "/reel/B/", enabledSections: bothEnabled))
        XCTAssertTrue(tracker.update(path: "/reel/C/", enabledSections: bothEnabled))
    }

    func testLeavingToDirectMessagesResetsSession() {
        var tracker = ReelsSessionTracker()
        _ = tracker.update(path: "/reel/A/", enabledSections: bothEnabled)
        _ = tracker.update(path: "/reel/B/", enabledSections: bothEnabled)
        XCTAssertFalse(tracker.update(path: "/direct/inbox/", enabledSections: bothEnabled))
    }

    func testFreshColdEntryAfterLeavingIsExemptAgain() {
        var tracker = ReelsSessionTracker()
        _ = tracker.update(path: "/reel/A/", enabledSections: bothEnabled)
        _ = tracker.update(path: "/reel/B/", enabledSections: bothEnabled)
        _ = tracker.update(path: "/direct/inbox/", enabledSections: bothEnabled)
        XCTAssertFalse(tracker.update(path: "/reel/D/", enabledSections: bothEnabled))
    }

    func testIndividualReelWhileAlreadyInTabSessionStaysCounted() {
        var tracker = ReelsSessionTracker()
        XCTAssertTrue(tracker.update(path: "/reels/", enabledSections: bothEnabled))
        XCTAssertTrue(tracker.update(path: "/reels/xyz123/", enabledSections: bothEnabled))
    }

    func testHomeFeedIsNeverRestrictedAndResetsSession() {
        var tracker = ReelsSessionTracker()
        _ = tracker.update(path: "/reel/A/", enabledSections: bothEnabled)
        _ = tracker.update(path: "/reel/B/", enabledSections: bothEnabled)
        XCTAssertFalse(tracker.update(path: "/", enabledSections: bothEnabled))
    }

    func testSwitchingFromReelsTabToExploreTabStaysCounted() {
        var tracker = ReelsSessionTracker()
        XCTAssertTrue(tracker.update(path: "/reels/", enabledSections: bothEnabled))
        XCTAssertTrue(tracker.update(path: "/explore/", enabledSections: bothEnabled))
    }

    func testProfilePageIsNotRestrictedAndResetsSession() {
        var tracker = ReelsSessionTracker()
        _ = tracker.update(path: "/reel/A/", enabledSections: bothEnabled)
        _ = tracker.update(path: "/reel/B/", enabledSections: bothEnabled)
        XCTAssertFalse(tracker.update(path: "/someusername/", enabledSections: bothEnabled))
    }

    func testDisablingExploreStopsItFromKeepingReelsSessionSticky() {
        var tracker = ReelsSessionTracker()
        XCTAssertTrue(tracker.update(path: "/reels/", enabledSections: bothEnabled))
        // Explore disabled mid-session: visiting it should now read as leaving
        // restricted territory, not staying in a sticky session.
        XCTAssertFalse(tracker.update(path: "/explore/", enabledSections: [.reels]))
    }

    func testReelsSectionDisabledMeansReelsNeverCounts() {
        var tracker = ReelsSessionTracker()
        XCTAssertFalse(tracker.update(path: "/reels/", enabledSections: [.explore]))
        XCTAssertFalse(tracker.update(path: "/reel/A/", enabledSections: [.explore]))
        XCTAssertFalse(tracker.update(path: "/reel/B/", enabledSections: [.explore]))
    }
}
