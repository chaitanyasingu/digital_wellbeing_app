package com.digitalwellbeing.digital_wellbeing_app

import android.app.Activity
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.Manifest
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val APP_CHANNEL = "digital_wellbeing/apps"
    private val ENFORCEMENT_CHANNEL = "digital_wellbeing/enforcement"
    private val NOTIFICATION_CHANNEL = "digital_wellbeing/notifications"
    private val USAGE_STATS_CHANNEL = "digital_wellbeing/usage_stats"
    private val STEPS_CHANNEL = "digital_wellbeing/steps"
    private val WIFI_CHANNEL = "digital_wellbeing/wifi"
    private val LOCATION_CHANNEL = "digital_wellbeing/location"
    private val DEVICE_ADMIN_CHANNEL = "digital_wellbeing/device_admin"
    private val NOTIFICATION_PERMISSION_REQUEST = 1001
    private val DEVICE_ADMIN_REQUEST = 1002
    private val LOCATION_PERMISSION_REQUEST = 1003
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var notificationPermissionResult: MethodChannel.Result? = null
    private var deviceAdminResult: MethodChannel.Result? = null
    private var locationPermissionResult: MethodChannel.Result? = null
    private lateinit var usageStatsBridge: UsageStatsBridge
    private lateinit var stepCounterBridge: StepCounterBridge
    private lateinit var wifiBridge: WifiBridge
    private lateinit var locationBridge: LocationBridge
    private lateinit var deviceAdminBridge: DeviceAdminBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        usageStatsBridge = UsageStatsBridge(this)
        stepCounterBridge = StepCounterBridge(this)
        wifiBridge = WifiBridge(this)
        locationBridge = LocationBridge(this)
        deviceAdminBridge = DeviceAdminBridge(this)

        // Apps channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    // Run on background thread to avoid blocking main thread
                    executor.execute {
                        try {
                            val apps = getInstalledApps()
                            mainHandler.post {
                                result.success(apps)
                            }
                        } catch (e: Exception) {
                            mainHandler.post {
                                result.error("ERROR", "Failed to get installed apps: ${e.message}", null)
                            }
                        }
                    }
                }
                "getCurrentApp" -> {
                    // This would require usage stats permission
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Enforcement channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ENFORCEMENT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startEnforcement" -> {
                    val allowedApps = call.argument<List<String>>("allowedApps") ?: emptyList()
                    val startTime = call.argument<String>("startTime") ?: "21:00"
                    val endTime = call.argument<String>("endTime") ?: "10:00"
                    
                    android.util.Log.d("MainActivity", "=== Starting enforcement ===")
                    android.util.Log.d("MainActivity", "Allowed apps count: ${allowedApps.size}")
                    android.util.Log.d("MainActivity", "Restriction window: $startTime - $endTime")
                    android.util.Log.d("MainActivity", "Allowed apps list: ${allowedApps.joinToString(", ")}")
                    
                    // Save to shared preferences with commit() instead of apply() for immediate persistence
                    val prefs = getSharedPreferences("enforcement_prefs", MODE_PRIVATE)
                    prefs.edit().apply {
                        clear() // Clear old data to prevent stale data
                        putStringSet("allowed_apps", allowedApps.toSet())
                        putString("start_time", startTime)
                        putString("end_time", endTime)
                        putBoolean("enforcement_enabled", true)
                        putLong("last_known_time", System.currentTimeMillis())
                        commit() // Use commit() instead of apply() for synchronous write
                    }
                    
                    // Verify what was saved
                    val savedApps = prefs.getStringSet("allowed_apps", emptySet())
                    val savedStart = prefs.getString("start_time", "")
                    val savedEnd = prefs.getString("end_time", "")
                    android.util.Log.d("MainActivity", "[VERIFICATION] Saved to SharedPreferences - Apps: ${savedApps?.size}, Start: $savedStart, End: $savedEnd")
                    android.util.Log.d("MainActivity", "[VERIFICATION] Saved apps list: ${savedApps?.joinToString(", ")}")
                    
                    if (savedApps?.isEmpty() == true) {
                        android.util.Log.w("MainActivity", "[WARNING] No allowed apps were saved!")
                    }
                    
                    // Schedule restriction notifications
                    RestrictionNotificationReceiver.scheduleRestrictionAlerts(this, startTime, endTime)
                    
                    // Start foreground service
                    val serviceIntent = Intent(this, EnforcementForegroundService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    
                    android.util.Log.d("MainActivity", "[SERVICE_START] Foreground service started")
                    result.success(true)
                }
                "stopEnforcement" -> {
                    android.util.Log.d("MainActivity", "[STOP] Stopping enforcement service")
                    
                    val prefs = getSharedPreferences("enforcement_prefs", MODE_PRIVATE)
                    prefs.edit().apply {
                        putBoolean("enforcement_enabled", false)
                        commit() // Use commit() for synchronous write
                    }
                    
                    android.util.Log.d("MainActivity", "[STOP] Set enforcement_enabled to false in SharedPreferences")
                    
                    // Cancel restriction notifications
                    RestrictionNotificationReceiver.cancelRestrictionAlerts(this)
                    
                    // Stop foreground service
                    val serviceIntent = Intent(this, EnforcementForegroundService::class.java)
                    stopService(serviceIntent)
                    
                    android.util.Log.d("MainActivity", "[STOP] Enforcement service stopped")
                    result.success(true)
                }
                "isAccessibilityEnabled" -> {
                    val enabled = isAccessibilityServiceEnabled()
                    result.success(enabled)
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                "updateContextFlags" -> {
                    val wifiRelaxed = call.argument<Boolean>("wifiRelaxed") ?: false
                    val locationStrict = call.argument<Boolean>("locationStrict") ?: false
                    val contractActive = call.argument<Boolean>("contractActive") ?: false
                    val hardmodeEnabled = call.argument<Boolean>("hardmodeEnabled") ?: false
                    val prefs = getSharedPreferences("enforcement_prefs", MODE_PRIVATE)
                    prefs.edit().apply {
                        putBoolean("wifi_relaxed_active", wifiRelaxed)
                        putBoolean("location_strict_active", locationStrict)
                        putBoolean("contract_active", contractActive)
                        putBoolean("hardmode_enabled", hardmodeEnabled)
                        commit()
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // WiFi channel (Phase 8)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIFI_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> result.success(wifiBridge.hasPermission())
                "getCurrentSsid" -> result.success(wifiBridge.getCurrentSsid())
                "isWifiEnabled" -> result.success(wifiBridge.isWifiEnabled())
                else -> result.notImplemented()
            }
        }

        // Location channel (Phase 8)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> result.success(locationBridge.hasPermission())
                "hasBackgroundPermission" -> result.success(locationBridge.hasBackgroundPermission())
                "requestPermission" -> {
                    locationPermissionResult = result
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(
                            Manifest.permission.ACCESS_FINE_LOCATION,
                            Manifest.permission.ACCESS_COARSE_LOCATION
                        ),
                        LOCATION_PERMISSION_REQUEST
                    )
                }
                "getLastKnownLocation" -> {
                    executor.execute {
                        try {
                            val loc = locationBridge.getLastKnownLocation()
                            mainHandler.post { result.success(loc) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Device Admin channel (Phase 8)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_ADMIN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAdminActive" -> result.success(deviceAdminBridge.isAdminActive())
                "activateAdmin" -> {
                    deviceAdminResult = result
                    val intent = deviceAdminBridge.buildActivateIntent()
                    startActivityForResult(intent, DEVICE_ADMIN_REQUEST)
                }
                "deactivateAdmin" -> {
                    deviceAdminBridge.deactivate()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Usage Stats channel (Phase 5)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USAGE_STATS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> result.success(usageStatsBridge.hasPermission())
                "openSettings" -> {
                    usageStatsBridge.openSettings(this)
                    result.success(null)
                }
                "getUsageStats" -> {
                    val startMs = (call.argument<Any>("startMs") as? Number)?.toLong() ?: 0L
                    val endMs = (call.argument<Any>("endMs") as? Number)?.toLong() ?: System.currentTimeMillis()
                    executor.execute {
                        try {
                            val stats = usageStatsBridge.getUsageStats(startMs, endMs)
                            mainHandler.post { result.success(stats) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "getPickupCount" -> {
                    val startMs = (call.argument<Any>("startMs") as? Number)?.toLong() ?: 0L
                    val endMs = (call.argument<Any>("endMs") as? Number)?.toLong() ?: System.currentTimeMillis()
                    executor.execute {
                        try {
                            val count = usageStatsBridge.getPickupCount(startMs, endMs)
                            mainHandler.post { result.success(count) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "getFirstPickupTime" -> {
                    val startMs = (call.argument<Any>("startMs") as? Number)?.toLong() ?: 0L
                    val endMs = (call.argument<Any>("endMs") as? Number)?.toLong() ?: System.currentTimeMillis()
                    executor.execute {
                        try {
                            val time = usageStatsBridge.getFirstPickupTime(startMs, endMs)
                            mainHandler.post { result.success(time) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "getLastPickupTime" -> {
                    val startMs = (call.argument<Any>("startMs") as? Number)?.toLong() ?: 0L
                    val endMs = (call.argument<Any>("endMs") as? Number)?.toLong() ?: System.currentTimeMillis()
                    executor.execute {
                        try {
                            val time = usageStatsBridge.getLastPickupTime(startMs, endMs)
                            mainHandler.post { result.success(time) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "scheduleSmartNotification" -> {
                    val type = call.argument<String>("type") ?: return@setMethodCallHandler result.error("INVALID", "type required", null)
                    val hour = call.argument<Int>("hour") ?: 8
                    val minute = call.argument<Int>("minute") ?: 0
                    SmartNotificationReceiver.schedule(this, type, hour, minute)
                    result.success(null)
                }
                "cancelSmartNotification" -> {
                    val type = call.argument<String>("type") ?: return@setMethodCallHandler result.error("INVALID", "type required", null)
                    SmartNotificationReceiver.cancel(this, type)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Step Counter channel (Phase 6)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STEPS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(stepCounterBridge.isAvailable())
                "hasPermission" -> result.success(stepCounterBridge.hasPermission())
                "requestPermission" -> {
                    stepCounterBridge.requestPermission(this)
                    result.success(null)
                }
                "getStepsToday" -> {
                    stepCounterBridge.getStepsToday { steps ->
                        mainHandler.post { result.success(steps) }
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Notification channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) 
                            == PackageManager.PERMISSION_GRANTED) {
                            result.success(true)
                        } else {
                            notificationPermissionResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                NOTIFICATION_PERMISSION_REQUEST
                            )
                        }
                    } else {
                        result.success(true) // Pre-Android 13, no permission needed
                    }
                }
                "hasNotificationPermission" -> {
                    val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val permissionStatus = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.POST_NOTIFICATIONS
                        )
                        permissionStatus == PackageManager.PERMISSION_GRANTED
                    } else {
                        true
                    }
                    result.success(hasPermission)
                }
                "showTestNotification" -> {
                    RestrictionNotificationReceiver().showRestrictionStartNotification(this)
                    result.success(null)
                }
                "showTamperWarning" -> {
                    val title = call.argument<String>("title") ?: "Warning"
                    val message = call.argument<String>("message") ?: "Tamper detected"
                    TamperWarningNotification.show(this, title, message)
                    result.success(null)
                }
                "showAppBlockingNotification" -> {
                    val endTime = call.argument<String>("endTime") ?: "10:00"
                    RestrictionNotificationReceiver().showAppBlockingNotification(this, endTime)
                    result.success(null)
                }
                "dismissAppBlockingNotification" -> {
                    RestrictionNotificationReceiver().dismissAppBlockingNotification(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == NOTIFICATION_PERMISSION_REQUEST) {
            val granted = grantResults.isNotEmpty() &&
                         grantResults[0] == PackageManager.PERMISSION_GRANTED
            notificationPermissionResult?.success(granted)
            notificationPermissionResult = null
        }
        if (requestCode == LOCATION_PERMISSION_REQUEST) {
            val granted = grantResults.isNotEmpty() &&
                         grantResults[0] == PackageManager.PERMISSION_GRANTED
            locationPermissionResult?.success(granted)
            locationPermissionResult = null
        }
        // Step counter / location permission results are also handled by the provider polling hasPermission()
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        return try {
            android.util.Log.d("MainActivity", "Getting installed apps...")
            val packageManager = packageManager
            val apps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
            android.util.Log.d("MainActivity", "Found ${apps.size} total apps")
            
            // Filter and limit to avoid excessive memory usage
            val launchableApps = apps
                .filter { app ->
                    try {
                        // Only include launchable apps (apps with a launcher intent)
                        packageManager.getLaunchIntentForPackage(app.packageName) != null
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "Error checking launch intent for ${app.packageName}: ${e.message}")
                        false
                    }
                }
                .mapNotNull { app ->
                    try {
                        mapOf(
                            "packageName" to app.packageName,
                            "appName" to packageManager.getApplicationLabel(app).toString(),
                            "isSystemApp" to ((app.flags and ApplicationInfo.FLAG_SYSTEM) != 0)
                        )
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "Error mapping app ${app.packageName}: ${e.message}")
                        null
                    }
                }
                .sortedBy { it["appName"] as String }
            
            android.util.Log.d("MainActivity", "Returning ${launchableApps.size} launchable apps")
            launchableApps
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error in getInstalledApps: ${e.message}")
            e.printStackTrace()
            emptyList()
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedComponentName = "$packageName/${AppBlockingService::class.java.canonicalName}"
        val enabledServicesSetting = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        
        return enabledServicesSetting.contains(expectedComponentName)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == DEVICE_ADMIN_REQUEST) {
            val active = deviceAdminBridge.isAdminActive()
            deviceAdminResult?.success(active)
            deviceAdminResult = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        executor.shutdown()
    }
}
