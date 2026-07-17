import XCTest
@testable import IGBlockCore

final class ReelsSessionTrackerTests: XCTestCase {
    func testEnteringReelsTabDirectlyIsRestrictedImmediately() {
        var tracker = ReelsSessionTracker()
        XCTAssertTrue(tracker.update(path: "/reels/"))
    }

    func testEnteringExploreTabDirectlyIsRestrictedImmediately() {
        var tracker = ReelsSessionTracker()
        XCTAssertTrue(tracker.update(path: "/explore/"))
    }

    func testFirstColdReelIsExempt() {
        var tracker = ReelsSessionTracker()
        XCTAssertFalse(tracker.update(path: "/reel/A/"))
    }

    func testSameColdReelPathRepeatedStaysExempt() {
        var tracker = ReelsSessionTracker()
        XCTAssertFalse(tracker.update(path: "/reel/A/"))
        XCTAssertFalse(tracker.update(path: "/reel/A/"))
    }

    func testSwipingToASecondDifferentReelStartsCounting() {
        var tracker = ReelsSessionTracker()
        XCTAssertFalse(tracker.update(path: "/reel/A/"))
        XCTAssertTrue(tracker.update(path: "/reel/B/"))
    }

    func testThirdReelStaysCountedOnceSessionStarted() {
        var tracker = ReelsSessionTracker()
        XCTAssertFalse(tracker.update(path: "/reel/A/"))
        XCTAssertTrue(tracker.update(path: "/reel/B/"))
        XCTAssertTrue(tracker.update(path: "/reel/C/"))
    }

    func testLeavingToDirectMessagesResetsSession() {
        var tracker = ReelsSessionTracker()
        _ = tracker.update(path: "/reel/A/")
        _ = tracker.update(path: "/reel/B/")
        XCTAssertFalse(tracker.update(path: "/direct/inbox/"))
    }

    func testFreshColdEntryAfterLeavingIsExemptAgain() {
        var tracker = ReelsSessionTracker()
        _ = tracker.update(path: "/reel/A/")
        _ = tracker.update(path: "/reel/B/")
        _ = tracker.update(path: "/direct/inbox/")
        XCTAssertFalse(tracker.update(path: "/reel/D/"))
    }

    func testIndividualReelWhileAlreadyInTabSessionStaysCounted() {
        var tracker = ReelsSessionTracker()
        XCTAssertTrue(tracker.update(path: "/reels/"))
        XCTAssertTrue(tracker.update(path: "/reels/xyz123/"))
    }

    func testHomeFeedIsNeverRestrictedAndResetsSession() {
        var tracker = ReelsSessionTracker()
        _ = tracker.update(path: "/reel/A/")
        _ = tracker.update(path: "/reel/B/")
        XCTAssertFalse(tracker.update(path: "/"))
    }

    func testSwitchingFromReelsTabToExploreTabStaysCounted() {
        var tracker = ReelsSessionTracker()
        XCTAssertTrue(tracker.update(path: "/reels/"))
        XCTAssertTrue(tracker.update(path: "/explore/"))
    }

    func testProfilePageIsNotRestrictedAndResetsSession() {
        var tracker = ReelsSessionTracker()
        _ = tracker.update(path: "/reel/A/")
        _ = tracker.update(path: "/reel/B/")
        XCTAssertFalse(tracker.update(path: "/someusername/"))
    }
}
