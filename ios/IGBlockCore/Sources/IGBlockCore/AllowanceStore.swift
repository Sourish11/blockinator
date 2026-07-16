import Foundation

public protocol AllowanceStore {
    var remainingSeconds: Int { get set }
    var lastResetEpochDay: Int { get set }
}

public final class UserDefaultsAllowanceStore: AllowanceStore {
    private let defaults: UserDefaults
    private static let remainingSecondsKey = "remaining_seconds"
    private static let lastResetEpochDayKey = "last_reset_epoch_day"

    public static let defaultDailyAllowanceSeconds = 900

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var remainingSeconds: Int {
        get {
            if defaults.object(forKey: Self.remainingSecondsKey) == nil {
                return Self.defaultDailyAllowanceSeconds
            }
            return defaults.integer(forKey: Self.remainingSecondsKey)
        }
        set { defaults.set(newValue, forKey: Self.remainingSecondsKey) }
    }

    public var lastResetEpochDay: Int {
        get {
            if defaults.object(forKey: Self.lastResetEpochDayKey) == nil {
                return -1
            }
            return defaults.integer(forKey: Self.lastResetEpochDayKey)
        }
        set { defaults.set(newValue, forKey: Self.lastResetEpochDayKey) }
    }
}
