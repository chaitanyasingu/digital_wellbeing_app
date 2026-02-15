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
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED -> {
                Log.d(TAG, "System time changed detected")
                
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val lastKnownTime = prefs.getLong(KEY_LAST_KNOWN_TIME, 0)
                val currentTime = System.currentTimeMillis()
                
                // Update last known time
                prefs.edit().putLong(KEY_LAST_KNOWN_TIME, currentTime).apply()
                
                // Check if time was changed backwards significantly (> 5 minutes)
                if (lastKnownTime > 0) {
                    val timeDiff = currentTime - lastKnownTime
                    if (timeDiff < -(5 * 60 * 1000)) { // 5 minutes backwards
                        Log.w(TAG, "Suspicious time change detected: $timeDiff ms")
                        // Time was changed backwards - still enforce based on actual restriction window
                    }
                }
            }
        }
    }
}
