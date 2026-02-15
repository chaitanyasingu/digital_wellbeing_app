package com.digitalwellbeing.digital_wellbeing_app

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val APP_CHANNEL = "digital_wellbeing/apps"
    private val ENFORCEMENT_CHANNEL = "digital_wellbeing/enforcement"
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
                    
                    // Save to shared preferences
                    val prefs = getSharedPreferences("enforcement_prefs", MODE_PRIVATE)
                    prefs.edit().apply {
                        putStringSet("allowed_apps", allowedApps.toSet())
                        putString("start_time", startTime)
                        putString("end_time", endTime)
                        putBoolean("enforcement_enabled", true)
                        putLong("last_known_time", System.currentTimeMillis())
                        apply()
                    }
                    
                    // Start foreground service
                    val serviceIntent = Intent(this, EnforcementForegroundService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    
                    result.success(true)
                }
                "stopEnforcement" -> {
                    val prefs = getSharedPreferences("enforcement_prefs", MODE_PRIVATE)
                    prefs.edit().putBoolean("enforcement_enabled", false).apply()
                    
                    // Stop foreground service
                    val serviceIntent = Intent(this, EnforcementForegroundService::class.java)
                    stopService(serviceIntent)
                    
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
                else -> result.notImplemented()
            }
        }
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

    override fun onDestroy() {
        super.onDestroy()
        executor.shutdown()
    }
}
