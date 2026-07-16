package com.sourish.igblock

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class FakeAllowanceStore(
    private var remainingSeconds: Int = 0,
    private var lastResetEpochDay: Long = -1L
) : AllowanceStore {
    override fun getRemainingSeconds() = remainingSeconds
    override fun setRemainingSeconds(seconds: Int) { remainingSeconds = seconds }
    override fun getLastResetEpochDay() = lastResetEpochDay
    override fun setLastResetEpochDay(epochDay: Long) { lastResetEpochDay = epochDay }
}

class AllowanceTrackerTest {

    @Test
    fun `resetIfNewDay grants full allowance on first ever run`() {
        val store = FakeAllowanceStore()
        val fixedToday = LocalDate.of(2026, 7, 15)
        val tracker = AllowanceTracker(store, dailyAllowanceSeconds = 900) { fixedToday }

        tracker.resetIfNewDay()

        assertEquals(900, tracker.remainingSeconds())
    }

    @Test
    fun `resetIfNewDay does not touch remaining seconds on the same day`() {
        val store = FakeAllowanceStore(
            remainingSeconds = 300,
            lastResetEpochDay = LocalDate.of(2026, 7, 15).toEpochDay()
        )
        val tracker = AllowanceTracker(store, dailyAllowanceSeconds = 900) { LocalDate.of(2026, 7, 15) }

        tracker.resetIfNewDay()

        assertEquals(300, tracker.remainingSeconds())
    }

    @Test
    fun `resetIfNewDay grants full allowance again on a new day`() {
        val store = FakeAllowanceStore(
            remainingSeconds = 0,
            lastResetEpochDay = LocalDate.of(2026, 7, 15).toEpochDay()
        )
        val tracker = AllowanceTracker(store, dailyAllowanceSeconds = 900) { LocalDate.of(2026, 7, 16) }

        tracker.resetIfNewDay()

        assertEquals(900, tracker.remainingSeconds())
    }

    @Test
    fun `consumeSecond decrements remaining seconds`() {
        val store = FakeAllowanceStore(remainingSeconds = 10)
        val tracker = AllowanceTracker(store)

        tracker.consumeSecond()

        assertEquals(9, tracker.remainingSeconds())
    }

    @Test
    fun `consumeSecond never goes below zero`() {
        val store = FakeAllowanceStore(remainingSeconds = 0)
        val tracker = AllowanceTracker(store)

        tracker.consumeSecond()

        assertEquals(0, tracker.remainingSeconds())
    }

    @Test
    fun `isExhausted is true only at zero`() {
        val store = FakeAllowanceStore(remainingSeconds = 1)
        val tracker = AllowanceTracker(store)
        assertFalse(tracker.isExhausted())

        tracker.consumeSecond()

        assertTrue(tracker.isExhausted())
    }
}
