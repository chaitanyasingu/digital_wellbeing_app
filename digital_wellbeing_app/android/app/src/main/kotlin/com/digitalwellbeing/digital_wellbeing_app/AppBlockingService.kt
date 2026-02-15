package com.digitalwellbeing.digital_wellbeing_app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import java.text.SimpleDateFormat
import java.util.*

class AppBlockingService : AccessibilityService() {

    companion object {
        private const val TAG = "AppBlockingService"
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            // Ignore our own app
            if (packageName == applicationContext.packageName) {
                return
            }

            // Check if enforcement is enabled
            val prefs = getSharedPreferences("enforcement_prefs", MODE_PRIVATE)
            val enforcementEnabled = prefs.getBoolean("enforcement_enabled", false)
            
            if (!enforcementEnabled) {
                return
            }

            // Check if currently in restriction window
            val startTime = prefs.getString("start_time", "21:00") ?: "21:00"
            val endTime = prefs.getString("end_time", "10:00") ?: "10:00"
            
            if (!isCurrentTimeRestricted(startTime, endTime)) {
                return
            }

            // Check if app is in allowed list
            val allowedApps = prefs.getStringSet("allowed_apps", emptySet()) ?: emptySet()
            
            if (packageName !in allowedApps) {
                Log.d(TAG, "Blocking app: $packageName")
                blockApp(packageName)
            }
        }
    }

    private fun blockApp(packageName: String) {
        // Launch blocking overlay
        val intent = Intent(this, BlockingActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
            putExtra("blocked_package", packageName)
        }
        startActivity(intent)

        // Return to home
        performGlobalAction(GLOBAL_ACTION_HOME)
    }

    private fun isCurrentTimeRestricted(startTime: String, endTime: String): Boolean {
        try {
            val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
            val now = Calendar.getInstance()
            val currentMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
            
            val start = timeFormat.parse(startTime)
            val startCal = Calendar.getInstance().apply { time = start!! }
            val startMinutes = startCal.get(Calendar.HOUR_OF_DAY) * 60 + startCal.get(Calendar.MINUTE)
            
            val end = timeFormat.parse(endTime)
            val endCal = Calendar.getInstance().apply { time = end!! }
            val endMinutes = endCal.get(Calendar.HOUR_OF_DAY) * 60 + endCal.get(Calendar.MINUTE)
            
            // If start < end (e.g., 09:00 to 17:00)
            if (startMinutes < endMinutes) {
                return currentMinutes in startMinutes until endMinutes
            }
            
            // If start > end (crosses midnight, e.g., 21:00 to 10:00)
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing time", e)
            return false
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Service connected")
    }
}
