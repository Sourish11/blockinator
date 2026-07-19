import Foundation

public final class AllowanceTracker {
    private var store: AllowanceStore
    private let dailyAllowanceSeconds: () -> Int
    private let today: () -> Date

    public init(
        store: AllowanceStore,
        dailyAllowanceSeconds: @escaping () -> Int = { UserDefaultsAllowanceStore.defaultDailyAllowanceSeconds },
        today: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.dailyAllowanceSeconds = dailyAllowanceSeconds
        self.today = today
    }

    public func resetIfNewDay() {
        let todayEpochDay = Self.epochDay(for: today())
        if store.lastResetEpochDay != todayEpochDay {
            store.remainingSeconds = dailyAllowanceSeconds()
            store.lastResetEpochDay = todayEpochDay
        }
    }

    public func isExhausted() -> Bool {
        store.remainingSeconds <= 0
    }

    public func consumeSecond() {
        let remaining = store.remainingSeconds
        if remaining > 0 {
            store.remainingSeconds = remaining - 1
        }
    }

    public func remainingSeconds() -> Int {
        store.remainingSeconds
    }

    /// Applies a new daily allowance immediately, for the rest of today — not waiting
    /// for the next day-boundary reset. Used when the user changes the duration in
    /// Settings mid-session: their remaining time for today becomes exactly the new
    /// limit (not adjusted by how much was already used).
    public func applyNewDailyAllowance(_ seconds: Int) {
        store.remainingSeconds = seconds
    }

    private static func epochDay(for date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let epoch = Date(timeIntervalSince1970: 0)
        return calendar.dateComponents([.day], from: epoch, to: date).day!
    }
}
