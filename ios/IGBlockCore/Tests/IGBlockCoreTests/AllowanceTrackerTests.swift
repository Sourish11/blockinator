import XCTest
@testable import IGBlockCore

final class FakeAllowanceStore: AllowanceStore {
    var remainingSeconds: Int
    var lastResetEpochDay: Int

    init(remainingSeconds: Int = 0, lastResetEpochDay: Int = -1) {
        self.remainingSeconds = remainingSeconds
        self.lastResetEpochDay = lastResetEpochDay
    }
}

private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.timeZone = TimeZone(identifier: "UTC")
    return calendar.date(from: components)!
}

final class AllowanceTrackerTests: XCTestCase {
    func testResetIfNewDayGrantsFullAllowanceOnFirstEverRun() {
        let store = FakeAllowanceStore()
        let fixedToday = date(2026, 7, 15)
        let tracker = AllowanceTracker(store: store, dailyAllowanceSeconds: { 900 }, today: { fixedToday })

        tracker.resetIfNewDay()

        XCTAssertEqual(tracker.remainingSeconds(), 900)
    }

    func testResetIfNewDayDoesNotTouchRemainingSecondsOnTheSameDay() {
        let store = FakeAllowanceStore(remainingSeconds: 300, lastResetEpochDay: AllowanceTrackerTests.epochDay(date(2026, 7, 15)))
        let tracker = AllowanceTracker(store: store, dailyAllowanceSeconds: { 900 }, today: { date(2026, 7, 15) })

        tracker.resetIfNewDay()

        XCTAssertEqual(tracker.remainingSeconds(), 300)
    }

    func testResetIfNewDayGrantsFullAllowanceAgainOnANewDay() {
        let store = FakeAllowanceStore(remainingSeconds: 0, lastResetEpochDay: AllowanceTrackerTests.epochDay(date(2026, 7, 15)))
        let tracker = AllowanceTracker(store: store, dailyAllowanceSeconds: { 900 }, today: { date(2026, 7, 16) })

        tracker.resetIfNewDay()

        XCTAssertEqual(tracker.remainingSeconds(), 900)
    }

    func testResetIfNewDayReadsTheAllowanceClosureFreshEachTime() {
        // Simulates the real app: dailyAllowanceSeconds reads a live setting rather
        // than a value frozen at construction time.
        var currentAllowance = 300
        let store = FakeAllowanceStore(remainingSeconds: 0, lastResetEpochDay: AllowanceTrackerTests.epochDay(date(2026, 7, 15)))
        let tracker = AllowanceTracker(store: store, dailyAllowanceSeconds: { currentAllowance }, today: { date(2026, 7, 16) })

        currentAllowance = 1800
        tracker.resetIfNewDay()

        XCTAssertEqual(tracker.remainingSeconds(), 1800)
    }

    func testConsumeSecondDecrementsRemainingSeconds() {
        let store = FakeAllowanceStore(remainingSeconds: 10)
        let tracker = AllowanceTracker(store: store)

        tracker.consumeSecond()

        XCTAssertEqual(tracker.remainingSeconds(), 9)
    }

    func testConsumeSecondNeverGoesBelowZero() {
        let store = FakeAllowanceStore(remainingSeconds: 0)
        let tracker = AllowanceTracker(store: store)

        tracker.consumeSecond()

        XCTAssertEqual(tracker.remainingSeconds(), 0)
    }

    func testIsExhaustedIsTrueOnlyAtZero() {
        let store = FakeAllowanceStore(remainingSeconds: 1)
        let tracker = AllowanceTracker(store: store)
        XCTAssertFalse(tracker.isExhausted())

        tracker.consumeSecond()

        XCTAssertTrue(tracker.isExhausted())
    }

    func testApplyNewDailyAllowanceSetsRemainingSecondsImmediately() {
        let store = FakeAllowanceStore(remainingSeconds: 50)
        let tracker = AllowanceTracker(store: store)

        tracker.applyNewDailyAllowance(1200)

        XCTAssertEqual(tracker.remainingSeconds(), 1200)
    }

    func testApplyNewDailyAllowanceDoesNotWaitForADayBoundary() {
        let store = FakeAllowanceStore(remainingSeconds: 0, lastResetEpochDay: AllowanceTrackerTests.epochDay(date(2026, 7, 15)))
        let tracker = AllowanceTracker(store: store, dailyAllowanceSeconds: { 900 }, today: { date(2026, 7, 15) })

        tracker.applyNewDailyAllowance(600)
        // Still the same day -- resetIfNewDay should NOT overwrite the just-applied value.
        tracker.resetIfNewDay()

        XCTAssertEqual(tracker.remainingSeconds(), 600)
    }

    private static func epochDay(_ date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let epoch = Date(timeIntervalSince1970: 0)
        return calendar.dateComponents([.day], from: epoch, to: date).day!
    }
}
