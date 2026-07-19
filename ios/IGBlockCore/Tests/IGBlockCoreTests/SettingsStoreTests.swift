import XCTest
@testable import IGBlockCore

final class SettingsStoreTests: XCTestCase {
    private func freshDefaults() -> UserDefaults {
        let suiteName = "SettingsStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func testDefaultDailyAllowanceMinutesIsFifteenWhenUnset() {
        let store = UserDefaultsSettingsStore(defaults: freshDefaults())
        XCTAssertEqual(store.dailyAllowanceMinutes, 15)
    }

    func testBothSectionsAreRestrictedByDefault() {
        let store = UserDefaultsSettingsStore(defaults: freshDefaults())
        XCTAssertTrue(store.isReelsRestricted)
        XCTAssertTrue(store.isExploreRestricted)
        XCTAssertEqual(store.enabledSections, [.reels, .explore])
    }

    func testDailyAllowanceMinutesPersistsAfterSet() {
        let store = UserDefaultsSettingsStore(defaults: freshDefaults())
        store.dailyAllowanceMinutes = 45
        XCTAssertEqual(store.dailyAllowanceMinutes, 45)
    }

    func testDailyAllowanceMinutesClampsAboveMaximum() {
        let store = UserDefaultsSettingsStore(defaults: freshDefaults())
        store.dailyAllowanceMinutes = 999
        XCTAssertEqual(store.dailyAllowanceMinutes, 120)
    }

    func testDailyAllowanceMinutesClampsBelowMinimum() {
        let store = UserDefaultsSettingsStore(defaults: freshDefaults())
        store.dailyAllowanceMinutes = 0
        XCTAssertEqual(store.dailyAllowanceMinutes, 1)
    }

    func testTogglingReelsRestrictionOffUpdatesEnabledSections() {
        let store = UserDefaultsSettingsStore(defaults: freshDefaults())
        store.isReelsRestricted = false
        XCTAssertEqual(store.enabledSections, [.explore])
    }

    func testTogglingExploreRestrictionOffUpdatesEnabledSections() {
        let store = UserDefaultsSettingsStore(defaults: freshDefaults())
        store.isExploreRestricted = false
        XCTAssertEqual(store.enabledSections, [.reels])
    }

    func testTogglingBothOffLeavesEnabledSectionsEmpty() {
        let store = UserDefaultsSettingsStore(defaults: freshDefaults())
        store.isReelsRestricted = false
        store.isExploreRestricted = false
        XCTAssertEqual(store.enabledSections, [])
    }
}
