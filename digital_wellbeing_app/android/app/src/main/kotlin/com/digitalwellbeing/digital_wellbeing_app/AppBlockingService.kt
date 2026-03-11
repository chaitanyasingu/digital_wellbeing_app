package com.digitalwellbeing.digital_wellbeing_app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.Button
import android.widget.TextView
import android.graphics.PixelFormat
import android.app.ActivityManager
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
    
    @Volatile private var currentBlockingView: LinearLayout? = null
    @Volatile private var currentBlockedPackageName: String? = null  // Track which app's overlay is showing
    private val windowManager by lazy { getSystemService(WINDOW_SERVICE) as WindowManager }
    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }
    private val blockedAppsInProgress = mutableSetOf<String>()
    @Volatile private var lastBlockedTime = 0L  // Global debounce to prevent duplicate overlays from rapid accessibility events
    @Volatile private var lastGoHomeTime = 0L
    @Volatile private var cachedHomePackages: Set<String> = emptySet()
    @Volatile private var lastDismissedBlockedPackage: String? = null
    @Volatile private var lastDismissedBlockedAt = 0L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            Log.d(TAG, "=== Window change detected: $packageName ===")

            if (shouldIgnoreHomeTransition(packageName)) {
                return
            }
            
            // NEVER block system/launcher packages
            if (isAlwaysAllowedPackage(packageName)) {
                Log.d(TAG, "System/Launcher app - ALWAYS ALLOWED")
                return
            }

            if (!isLaunchableApp(packageName)) {
                Log.d(TAG, "Package $packageName has no launcher intent. Ignoring non-launchable component.")
                return
            }

            if (shouldSuppressRecentlyDismissedPackage(packageName)) {
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

    private fun shouldIgnoreHomeTransition(packageName: String): Boolean {
        val elapsed = System.currentTimeMillis() - lastGoHomeTime
        if (elapsed < 1500 && isAlwaysAllowedPackage(packageName)) {
            Log.d(TAG, "Ignoring $packageName during post-home cooldown (${elapsed}ms)")
            return true
        }
        return false
    }

    private fun isAlwaysAllowedPackage(packageName: String): Boolean {
        return SYSTEM_WHITELIST.contains(packageName) || getHomePackages().contains(packageName)
    }

    private fun getHomePackages(): Set<String> {
        if (cachedHomePackages.isNotEmpty()) {
            return cachedHomePackages
        }

        return try {
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
            }
            val resolvedHomes = packageManager.queryIntentActivities(
                homeIntent,
                PackageManager.MATCH_DEFAULT_ONLY
            ).map { it.activityInfo.packageName }.toSet()

            cachedHomePackages = resolvedHomes
            Log.d(TAG, "Resolved home packages: ${resolvedHomes.joinToString(", ")}")
            resolvedHomes
        } catch (e: Exception) {
            Log.e(TAG, "Failed to resolve home packages: ${e.message}", e)
            emptySet()
        }
    }

    private fun isLaunchableApp(packageName: String): Boolean {
        return try {
            packageManager.getLaunchIntentForPackage(packageName) != null
        } catch (e: Exception) {
            Log.e(TAG, "Failed to check launcher intent for $packageName: ${e.message}", e)
            false
        }
    }

    private fun shouldSuppressRecentlyDismissedPackage(packageName: String): Boolean {
        val dismissedPackage = lastDismissedBlockedPackage ?: return false
        val elapsed = System.currentTimeMillis() - lastDismissedBlockedAt

        if (dismissedPackage != packageName) {
            return false
        }

        if (elapsed < 3000) {
            Log.d(TAG, "Ignoring recently dismissed package $packageName for ${3000 - elapsed}ms")
            return true
        }

        lastDismissedBlockedPackage = null
        lastDismissedBlockedAt = 0L
        return false
    }

    private fun blockApp(packageName: String) {
        Log.d(TAG, "[BLOCK] blockApp() called for: $packageName")
        
        val currentTime = System.currentTimeMillis()
        
        // GLOBAL DEBOUNCE: Prevent showing ANY overlay within 1 second of last block
        // This prevents duplicate overlays from rapid accessibility events on the same app launch
        if ((currentTime - lastBlockedTime) < 1000) {
            Log.d(TAG, "[BLOCK] GLOBAL_DEBOUNCE: Last overlay shown ${currentTime - lastBlockedTime}ms ago. Ignoring this event.")
            return
        }
        
        // If an overlay is already visible, don't stack another one on top
        if (currentBlockedPackageName != null) {
            Log.d(TAG, "[BLOCK] ⚠ Overlay already showing for ${currentBlockedPackageName}. Skipping $packageName")
            return
        }
        
        // If this app is already mid-block, skip
        if (blockedAppsInProgress.contains(packageName)) {
            Log.d(TAG, "[BLOCK] $packageName is already being blocked, skipping")
            return
        }
        
        // Record this blocking attempt
        lastBlockedTime = currentTime
        
        // Add to blocking set immediately to prevent duplicate blocks
        blockedAppsInProgress.add(packageName)
        currentBlockedPackageName = packageName  // Track which app's overlay we're showing
        Log.d(TAG, "[BLOCK] Added $packageName to blocking in-progress set")
        
        Log.d(TAG, "=== BLOCKING APP FLOW STARTED FOR $packageName ===")
        
        try {
            // Step 1: Show blocking overlay immediately
            Log.d(TAG, "Step 1: Showing blocking overlay for $packageName")
            showBlockingOverlay(packageName)
            
            // Step 2: Kill the app process (happens while overlay is visible)
            Thread {
                Thread.sleep(300)  // Quick kill after showing overlay
                
                try {
                    Log.d(TAG, "Step 2: Killing process for $packageName")
                    closeBlockedApp(packageName)
                } catch (e: Exception) {
                    Log.e(TAG, "Error killing process: ${e.message}", e)
                }
                
                // NOTE: We do NOT auto-send to home or remove overlay here
                // The user will click "GO HOME" button on the overlay to proceed
                // This allows the overlay to stay visible until user takes action
                Log.d(TAG, "Overlay is now visible, waiting for user to click GO HOME button")
                
            }.start()
            
        } catch (e: Exception) {
            Log.e(TAG, "FATAL ERROR in blockApp: ${e.message}", e)
            e.printStackTrace()
            blockedAppsInProgress.remove(packageName)
        }
    }
    
    private fun showBlockingOverlay(packageName: String) {
        Log.d(TAG, "[OVERLAY] ========== CREATING OVERLAY FOR $packageName ==========")
        try {
            // Remove existing overlay if any
            if (currentBlockingView != null) {
                try {
                    Log.d(TAG, "[OVERLAY] Removing previous overlay before creating new one")
                    windowManager.removeView(currentBlockingView)
                } catch (e: Exception) {
                    Log.d(TAG, "[OVERLAY] Could not remove previous overlay")
                }
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
            
            Log.d(TAG, "Creating blocking overlay for $appName, unlock time: $endTime")
            
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
                text = "This app is restricted.\nAvailable again at $endTime\n\nUse this time for something meaningful 🌟"
                textSize = 16f
                setTextColor(0xFF888888.toInt())
                gravity = android.view.Gravity.CENTER
                setPadding(0, 0, 0, 48)
                lineHeight = (20 * resources.displayMetrics.scaledDensity).toInt()
            }
            
            val backButton = Button(this).apply {
                text = "GO HOME"
                textSize = 16f
                setPadding(48, 24, 48, 24)
                setBackgroundColor(0xFF6B4FA0.toInt())
                setTextColor(0xFFFFFFFF.toInt())
                setOnClickListener {
                    Log.d(TAG, "[BUTTON_CLICK] User clicked GO HOME button for $packageName")
                    lastGoHomeTime = System.currentTimeMillis()
                    lastDismissedBlockedPackage = packageName
                    lastDismissedBlockedAt = lastGoHomeTime
                    
                    // Use accessibility global action for immediate, reliable home navigation
                    performGlobalAction(GLOBAL_ACTION_HOME)
                    Log.d(TAG, "[BUTTON_CLICK] Performed GLOBAL_ACTION_HOME")
                    
                    // Remove overlay and cleanup on main thread after home animation completes
                    mainHandler.postDelayed({
                        closeBlockedApp(packageName)
                        removeBlockingOverlay()
                        
                        // Cleanup - clear all tracking so the app is blockable again next open
                        Log.d(TAG, "[BUTTON_CLICK] Removing $packageName from blocking in-progress set")
                        blockedAppsInProgress.remove(packageName)
                        currentBlockedPackageName = null  // Clear overlay tracking
                        Log.d(TAG, "[BUTTON_CLICK] ✓ Cleanup complete for $packageName")
                    }, 500)
                }
            }
            
            layout.addView(iconText)
            layout.addView(titleText)
            layout.addView(appNameText)
            layout.addView(messageText)
            layout.addView(backButton)
            
            // Store package name in tag for cleanup later
            layout.tag = packageName
            
            // Window manager params for overlay - FULL SCREEN, INTERACTIVE
            // IMPORTANT: Remove FLAG_NOT_FOCUSABLE so button can receive clicks!
            val params = WindowManager.LayoutParams().apply {
                type = WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                format = PixelFormat.TRANSLUCENT
                flags = (WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                    or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN)  // Stay within screen bounds
                width = WindowManager.LayoutParams.MATCH_PARENT
                height = WindowManager.LayoutParams.MATCH_PARENT
                x = 0
                y = 0
            }
            
            Log.d(TAG, "[OVERLAY] Adding overlay to window manager...")
            windowManager.addView(layout, params)
            currentBlockingView = layout
            Log.d(TAG, "[OVERLAY] ✓ Blocking overlay displayed successfully for $packageName")
            Log.d(TAG, "[OVERLAY] Overlay is now visible, waiting for user to click GO HOME button")
            
        } catch (e: Exception) {
            Log.e(TAG, "ERROR: Failed to show blocking overlay", e)
            e.printStackTrace()
        }
    }

    private fun closeBlockedApp(packageName: String) {
        try {
            val activityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
            activityManager.killBackgroundProcesses(packageName)
            Log.d(TAG, "killBackgroundProcesses() called for $packageName")
        } catch (e: Exception) {
            Log.e(TAG, "killBackgroundProcesses failed for $packageName: ${e.message}", e)
        }

        try {
            Runtime.getRuntime().exec(arrayOf("am", "force-stop", packageName)).waitFor()
            Log.d(TAG, "am force-stop executed for $packageName")
        } catch (e: Exception) {
            Log.d(TAG, "am force-stop failed (expected) for $packageName: ${e.message}")
        }
    }

    private fun removeBlockingOverlay() {
        try {
            if (currentBlockingView != null) {
                Log.d(TAG, "[OVERLAY] Removing overlay for $currentBlockedPackageName")
                windowManager.removeView(currentBlockingView)
                currentBlockingView = null
                Log.d(TAG, "[OVERLAY] ✓ Overlay removed successfully")
            } else {
                Log.d(TAG, "[OVERLAY] removeBlockingOverlay() called but no overlay exists")
            }
        } catch (e: Exception) {
            Log.e(TAG, "[OVERLAY] Error removing overlay: ${e.message}", e)
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
