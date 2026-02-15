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
        
        // System packages that should NEVER be blocked
        private val SYSTEM_WHITELIST = setOf(
            // Launchers
            "com.google.android.apps.nexuslauncher",  // Pixel Launcher
            "com.android.launcher3",                  // AOSP Launcher
            "com.android.launcher",                   // Generic launcher
            "com.sec.android.app.launcher",           // Samsung
            "com.miui.home",                          // Xiaomi
            "com.huawei.android.launcher",            // Huawei
            "com.oppo.launcher",                      // Oppo
            "com.oneplus.launcher",                   // OnePlus
            // System UI
            "com.android.systemui",
            "com.android.systemui.accessibility.accessibilitymenu",
            // Settings
            "com.android.settings",
            // Phone/Dialer (emergency calls)
            "com.google.android.dialer",
            "com.android.dialer",
            "com.android.contacts",
            // Our own app and blocking activity
            "com.digitalwellbeing.digital_wellbeing_app"
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            Log.d(TAG, "=== Window change detected: $packageName ===")
            
            // NEVER block system/launcher packages
            if (SYSTEM_WHITELIST.contains(packageName)) {
                Log.d(TAG, "System/Launcher app - ALWAYS ALLOWED")
                return
            }

            // Check if enforcement is enabled
            val prefs = getSharedPreferences("enforcement_prefs", MODE_PRIVATE)
            val enforcementEnabled = prefs.getBoolean("enforcement_enabled", false)
            
            Log.d(TAG, "Enforcement enabled: $enforcementEnabled")
            
            if (!enforcementEnabled) {
                Log.d(TAG, "Enforcement disabled, ignoring $packageName")
                return
            }

            // Check if currently in restriction window
            val startTime = prefs.getString("start_time", "21:00") ?: "21:00"
            val endTime = prefs.getString("end_time", "10:00") ?: "10:00"
            
            val isRestricted = isCurrentTimeRestricted(startTime, endTime)
            Log.d(TAG, "Restriction window: $startTime-$endTime, Currently restricted: $isRestricted")
            
            if (!isRestricted) {
                Log.d(TAG, "Not in restriction window, allowing $packageName")
                return
            }

            // Check if app is in allowed list
            val allowedApps = prefs.getStringSet("allowed_apps", emptySet()) ?: emptySet()
            Log.d(TAG, "Allowed apps count: ${allowedApps.size}")
            Log.d(TAG, "Allowed apps list: ${allowedApps.joinToString(", ")}")
            Log.d(TAG, "Checking if '$packageName' is in allowed list...")
            
            if (allowedApps.contains(packageName)) {
                Log.d(TAG, "✓ App $packageName IS in allowed list, ALLOWING")
                return
            } else {
                Log.d(TAG, "✗ App $packageName NOT in allowed list, BLOCKING")
                blockApp(packageName)
            }
        }
    }

    private fun blockApp(packageName: String) {
        Log.d(TAG, "Showing blocking dialog for $packageName")
        
        // Launch blocking overlay
        val intent = Intent(this, BlockingActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("blocked_package", packageName)
        }
        startActivity(intent)
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
            
            val currentTime = "${now.get(Calendar.HOUR_OF_DAY).toString().padStart(2, '0')}:${now.get(Calendar.MINUTE).toString().padStart(2, '0')}"
            
            Log.d(TAG, "Time check: Current=$currentTime ($currentMinutes min), Start=$startTime ($startMinutes min), End=$endTime ($endMinutes min)")
            
            val isRestricted: Boolean
            // If start < end (e.g., 09:00 to 17:00)
            if (startMinutes < endMinutes) {
                isRestricted = currentMinutes in startMinutes until endMinutes
                Log.d(TAG, "Same-day restriction: $currentMinutes in [$startMinutes, $endMinutes) = $isRestricted")
            } else {
                // If start > end (crosses midnight, e.g., 21:00 to 10:00)
                isRestricted = currentMinutes >= startMinutes || currentMinutes < endMinutes
                Log.d(TAG, "Overnight restriction: ($currentMinutes >= $startMinutes OR $currentMinutes < $endMinutes) = $isRestricted")
            }
            
            return isRestricted
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
