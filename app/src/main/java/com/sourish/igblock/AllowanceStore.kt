package com.sourish.igblock

import android.content.Context

interface AllowanceStore {
    fun getRemainingSeconds(): Int
    fun setRemainingSeconds(seconds: Int)
    fun getLastResetEpochDay(): Long
    fun setLastResetEpochDay(epochDay: Long)
}

class SharedPreferencesAllowanceStore(context: Context) : AllowanceStore {
    private val prefs = context.getSharedPreferences("allowance", Context.MODE_PRIVATE)

    override fun getRemainingSeconds(): Int =
        prefs.getInt(KEY_REMAINING_SECONDS, DEFAULT_DAILY_ALLOWANCE_SECONDS)

    override fun setRemainingSeconds(seconds: Int) {
        prefs.edit().putInt(KEY_REMAINING_SECONDS, seconds).commit()
    }

    override fun getLastResetEpochDay(): Long =
        prefs.getLong(KEY_LAST_RESET_EPOCH_DAY, -1L)

    override fun setLastResetEpochDay(epochDay: Long) {
        prefs.edit().putLong(KEY_LAST_RESET_EPOCH_DAY, epochDay).commit()
    }

    companion object {
        const val KEY_REMAINING_SECONDS = "remaining_seconds"
        const val KEY_LAST_RESET_EPOCH_DAY = "last_reset_epoch_day"
        const val DEFAULT_DAILY_ALLOWANCE_SECONDS = 900
    }
}
