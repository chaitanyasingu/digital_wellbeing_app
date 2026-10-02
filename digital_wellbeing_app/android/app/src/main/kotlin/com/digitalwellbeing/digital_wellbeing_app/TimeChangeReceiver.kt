package com.digitalwellbeing.digital_wellbeing_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class TimeChangeReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "TimeChangeReceiver"
        private const val PREFS_NAME = "enforcement_prefs"
        private const val KEY_LAST_KNOWN_TIME = "last_known_time"
        private const val BACKWARD_THRESHOLD_MS = 5 * 60 * 1000L // 5 minutes
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED -> {
                Log.d(TAG, "System time change detected")

                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val lastKnownTime = prefs.getLong(KEY_LAST_KNOWN_TIME, 0)
                val currentTime = System.currentTimeMillis()

                prefs.edit().putLong(KEY_LAST_KNOWN_TIME, currentTime).apply()

                if (lastKnownTime > 0) {
                    val timeDiff = currentTime - lastKnownTime
                    if (timeDiff < -BACKWARD_THRESHOLD_MS) {
                        Log.w(TAG, "Backward clock change detected: ${-timeDiff / 1000}s")
                        handleBackwardClockChange(context, prefs, lastKnownTime)
                    }
                }
            }
        }
    }

    private fun handleBackwardClockChange(
        context: Context,
        prefs: android.content.SharedPreferences,
        lastKnownTime: Long
    ) {
        val enforcementEnabled = prefs.getBoolean("enforcement_enabled", false)
        if (!enforcementEnabled) {
            Log.d(TAG, "Enforcement disabled — ignoring clock rollback")
            return
        }

        val startTime = prefs.getString("start_time", "21:00") ?: "21:00"
        val endTime = prefs.getString("end_time", "10:00") ?: "10:00"

        // Check whether we were inside a restriction window before the rollback.
        val wasRestricted = TimeUtils.isEpochTimeRestricted(lastKnownTime, startTime, endTime)
        Log.d(TAG, "Was restricted before rollback: $wasRestricted (window $startTime–$endTime)")

        if (wasRestricted) {
            Log.w(TAG, "Clock rolled back during restriction window — activating tamper override")
            prefs.edit().putBoolean("clock_tamper_active", true).commit()
            TamperWarningNotification.show(
                context,
                "Clock Tampering Detected",
                "System clock was set back during your mindful period. Restrictions remain active until $endTime."
            )
        }
    }
}

