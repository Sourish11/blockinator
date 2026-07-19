import Foundation

public protocol SettingsStore {
    var dailyAllowanceMinutes: Int { get set }
    var isReelsRestricted: Bool { get set }
    var isExploreRestricted: Bool { get set }
}

extension SettingsStore {
    public var enabledSections: Set<RestrictedSection> {
        var sections = Set<RestrictedSection>()
        if isReelsRestricted { sections.insert(.reels) }
        if isExploreRestricted { sections.insert(.explore) }
        return sections
    }
}

public final class UserDefaultsSettingsStore: SettingsStore {
    private let defaults: UserDefaults
    private static let dailyAllowanceMinutesKey = "daily_allowance_minutes"
    private static let isReelsRestrictedKey = "is_reels_restricted"
    private static let isExploreRestrictedKey = "is_explore_restricted"

    public static let defaultDailyAllowanceMinutes = 15
    public static let minDailyAllowanceMinutes = 1
    public static let maxDailyAllowanceMinutes = 120

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var dailyAllowanceMinutes: Int {
        get {
            if defaults.object(forKey: Self.dailyAllowanceMinutesKey) == nil {
                return Self.defaultDailyAllowanceMinutes
            }
            return defaults.integer(forKey: Self.dailyAllowanceMinutesKey)
        }
        set {
            let clamped = min(max(newValue, Self.minDailyAllowanceMinutes), Self.maxDailyAllowanceMinutes)
            defaults.set(clamped, forKey: Self.dailyAllowanceMinutesKey)
        }
    }

    public var isReelsRestricted: Bool {
        get {
            if defaults.object(forKey: Self.isReelsRestrictedKey) == nil {
                return true
            }
            return defaults.bool(forKey: Self.isReelsRestrictedKey)
        }
        set { defaults.set(newValue, forKey: Self.isReelsRestrictedKey) }
    }

    public var isExploreRestricted: Bool {
        get {
            if defaults.object(forKey: Self.isExploreRestrictedKey) == nil {
                return true
            }
            return defaults.bool(forKey: Self.isExploreRestrictedKey)
        }
        set { defaults.set(newValue, forKey: Self.isExploreRestrictedKey) }
    }
}
