package com.digitalwellbeing.digital_wellbeing_app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.Button
import android.widget.TextView
import android.graphics.PixelFormat
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
    
    private var currentBlockingView: LinearLayout? = null
    private val windowManager by lazy { getSystemService(WINDOW_SERVICE) as WindowManager }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            Log.d(TAG, "=== Window change detected: $packageName ===")
            
            // NEVER block system/launcher packages
            if (SYSTEM_WHITELIST.contains(packageName)) {
                Log.d(TAG, "System/Launcher app - ALWAYS ALLOWED")
                return
            }

            // Check if enforcement is enabled - Re-read from SharedPreferences each time
            val prefs = getSharedPreferences("enforcement_prefs", MODE_PRIVATE)
            
            // Force reload preferences from disk
            prefs.all // This forces Android to sync from disk
            
            val enforcementEnabled = prefs.getBoolean("enforcement_enabled", false)
            Log.d(TAG, "[ENFORCEMENT_CHECK] Enforcement enabled: $enforcementEnabled")
            
            if (!enforcementEnabled) {
                Log.d(TAG, "[ENFORCEMENT_CHECK] Enforcement disabled, ignoring $packageName")
                return
            }

            // Check if currently in restriction window
            val startTime = prefs.getString("start_time", "21:00") ?: "21:00"
            val endTime = prefs.getString("end_time", "10:00") ?: "10:00"
            
            val isRestricted = isCurrentTimeRestricted(startTime, endTime)
            Log.d(TAG, "[RESTRICTION_CHECK] Restriction window: $startTime-$endTime, Currently restricted: $isRestricted")
            
            if (!isRestricted) {
                Log.d(TAG, "[RESTRICTION_CHECK] Not in restriction window, allowing $packageName")
                return
            }

            // Check if app is in allowed list - Read fresh from preferences
            val allowedApps = prefs.getStringSet("allowed_apps", emptySet()) ?: emptySet()
            Log.d(TAG, "[ALLOWED_APPS_CHECK] Total allowed apps: ${allowedApps.size}")
            
            if (allowedApps.isEmpty()) {
                Log.w(TAG, "[ALLOWED_APPS_CHECK] WARNING: No allowed apps configured!")
            }
            
            Log.d(TAG, "[ALLOWED_APPS_CHECK] Allowed apps list: ${allowedApps.joinToString(", ")}")
            Log.d(TAG, "[ALLOWED_APPS_CHECK] Checking if '$packageName' is in allowed list...")
            
            val isAllowed = allowedApps.contains(packageName)
            Log.d(TAG, "[DECISION] Package $packageName - Allowed: $isAllowed")
            
            if (isAllowed) {
                Log.d(TAG, "[DECISION] ✓ App $packageName IS in allowed list, ALLOWING access")
                return
            } else {
                Log.d(TAG, "[DECISION] ✗ App $packageName NOT in allowed list, BLOCKING access")
                blockApp(packageName)
            }
        }
    }

    private fun blockApp(packageName: String) {
        Log.d(TAG, "Showing blocking overlay for $packageName")
        
        try {
            // Remove existing overlay if any
            if (currentBlockingView != null) {
                windowManager.removeView(currentBlockingView)
                currentBlockingView = null
            }
            
            // Get app name
            val appName = try {
                val pm = packageManager
                val appInfo = pm.getApplicationInfo(packageName, 0)
                pm.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to get app name: ${e.message}")
                packageName
            }
            
            // Get unlock time
            val prefs = getSharedPreferences("enforcement_prefs", MODE_PRIVATE)
            val endTime = prefs.getString("end_time", "10:00") ?: "10:00"
            
            Log.d(TAG, "Creating overlay for $appName, unlock time: $endTime")
            
            // Create overlay layout
            val layout = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(64, 64, 64, 64)
                gravity = android.view.Gravity.CENTER
                setBackgroundColor(0xFFF5F5F5.toInt())
            }
            
            // Icon
            val iconText = TextView(this).apply {
                text = "🧘"
                textSize = 64f
                gravity = android.view.Gravity.CENTER
                setPadding(0, 0, 0, 24)
            }
            
            val titleText = TextView(this).apply {
                text = "Mindful Moment"
                textSize = 28f
                setTextColor(0xFF6B4FA0.toInt())
                gravity = android.view.Gravity.CENTER
                setPadding(0, 0, 0, 16)
                setTypeface(null, android.graphics.Typeface.BOLD)
            }
            
            val appNameText = TextView(this).apply {
                text = appName
                textSize = 18f
                setTextColor(0xFF666666.toInt())
                gravity = android.view.Gravity.CENTER
                setPadding(0, 0, 0, 8)
            }
            
            val messageText = TextView(this).apply {
                text = "Taking a break from this app.\nAvailable again at $endTime\n\nUse this time for something meaningful 🌟"
                textSize = 16f
                setTextColor(0xFF888888.toInt())
                gravity = android.view.Gravity.CENTER
                setPadding(0, 0, 0, 48)
                lineHeight = (20 * resources.displayMetrics.scaledDensity).toInt()
            }
            
            val backButton = Button(this).apply {
                text = "GO BACK"
                textSize = 16f
                setPadding(48, 24, 48, 24)
                setBackgroundColor(0xFF6B4FA0.toInt())
                setTextColor(0xFFFFFFFF.toInt())
                setOnClickListener {
                    Log.d(TAG, "Back button clicked, returning to home")
                    // Close overlay and return to home
                    removeBlockingOverlay()
                    val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                        addCategory(Intent.CATEGORY_HOME)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(homeIntent)
                }
            }
            
            layout.addView(iconText)
            layout.addView(titleText)
            layout.addView(appNameText)
            layout.addView(messageText)
            layout.addView(backButton)
            
            // Window manager params for overlay
            val params = WindowManager.LayoutParams().apply {
                type = WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                format = PixelFormat.TRANSLUCENT
                flags = (WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE 
                    or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                    or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
                    or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
                width = WindowManager.LayoutParams.MATCH_PARENT
                height = WindowManager.LayoutParams.MATCH_PARENT
                x = 0
                y = 0
            }
            
            Log.d(TAG, "Adding overlay to window manager...")
            windowManager.addView(layout, params)
            currentBlockingView = layout
            Log.d(TAG, "Blocking overlay displayed successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "CRITICAL ERROR: Failed to show blocking overlay", e)
            e.printStackTrace()
        }
    }
    
    private fun removeBlockingOverlay() {
        try {
            if (currentBlockingView != null) {
                Log.d(TAG, "Removing blocking overlay")
                windowManager.removeView(currentBlockingView)
                currentBlockingView = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error removing overlay: ${e.message}", e)
        }
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
