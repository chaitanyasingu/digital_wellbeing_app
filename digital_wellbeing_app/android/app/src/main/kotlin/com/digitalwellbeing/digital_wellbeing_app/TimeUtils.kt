package com.digitalwellbeing.digital_wellbeing_app

import android.util.Log
import java.text.SimpleDateFormat
import java.util.*

object TimeUtils {
    private const val TAG = "TimeUtils"

    fun isCurrentTimeRestricted(startTime: String, endTime: String): Boolean {
        val cal = Calendar.getInstance()
        val minutes = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
        return isMinutesRestricted(minutes, startTime, endTime)
    }

    /** Check whether a specific epoch millisecond value falls within the restriction window. */
    fun isEpochTimeRestricted(epochMs: Long, startTime: String, endTime: String): Boolean {
        val cal = Calendar.getInstance().apply { timeInMillis = epochMs }
        val minutes = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
        return isMinutesRestricted(minutes, startTime, endTime)
    }

    private fun isMinutesRestricted(currentMinutes: Int, startTime: String, endTime: String): Boolean {
        return try {
            val fmt = SimpleDateFormat("HH:mm", Locale.getDefault())

            val startCal = Calendar.getInstance().apply { time = fmt.parse(startTime)!! }
            val startMinutes = startCal.get(Calendar.HOUR_OF_DAY) * 60 + startCal.get(Calendar.MINUTE)

            val endCal = Calendar.getInstance().apply { time = fmt.parse(endTime)!! }
            val endMinutes = endCal.get(Calendar.HOUR_OF_DAY) * 60 + endCal.get(Calendar.MINUTE)

            Log.d(TAG, "Restriction check: current=$currentMinutes start=$startMinutes end=$endMinutes")

            if (startMinutes < endMinutes) {
                // Same-day window (e.g. 09:00–17:00)
                currentMinutes in startMinutes until endMinutes
            } else {
                // Overnight window (e.g. 21:00–10:00)
                currentMinutes >= startMinutes || currentMinutes < endMinutes
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing time: ${e.message}", e)
            false
        }
    }
}
