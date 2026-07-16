import Foundation

public final class AllowanceTracker {
    private var store: AllowanceStore
    private let dailyAllowanceSeconds: Int
    private let today: () -> Date

    public init(
        store: AllowanceStore,
        dailyAllowanceSeconds: Int = UserDefaultsAllowanceStore.defaultDailyAllowanceSeconds,
        today: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.dailyAllowanceSeconds = dailyAllowanceSeconds
        self.today = today
    }

    public func resetIfNewDay() {
        let todayEpochDay = Self.epochDay(for: today())
        if store.lastResetEpochDay != todayEpochDay {
            store.remainingSeconds = dailyAllowanceSeconds
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

    private static func epochDay(for date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        let epoch = Date(timeIntervalSince1970: 0)
        return calendar.dateComponents([.day], from: epoch, to: date).day!
    }
}
