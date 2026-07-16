package com.sourish.igblock

import java.time.LocalDate

class AllowanceTracker(
    private val store: AllowanceStore,
    private val dailyAllowanceSeconds: Int = SharedPreferencesAllowanceStore.DEFAULT_DAILY_ALLOWANCE_SECONDS,
    private val today: () -> LocalDate = { LocalDate.now() }
) {
    fun resetIfNewDay() {
        val todayEpochDay = today().toEpochDay()
        if (store.getLastResetEpochDay() != todayEpochDay) {
            store.setRemainingSeconds(dailyAllowanceSeconds)
            store.setLastResetEpochDay(todayEpochDay)
        }
    }

    fun isExhausted(): Boolean = store.getRemainingSeconds() <= 0

    fun consumeSecond() {
        val remaining = store.getRemainingSeconds()
        if (remaining > 0) {
            store.setRemainingSeconds(remaining - 1)
        }
    }

    fun remainingSeconds(): Int = store.getRemainingSeconds()
}
