package com.digitalwellbeing.digital_wellbeing_app

import android.app.AppOpsManager
import android.app.Activity
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings

class UsageStatsBridge(private val context: Context) {

    fun hasPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun openSettings(activity: Activity) {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        activity.startActivity(intent)
    }

    fun getUsageStats(startMs: Long, endMs: Long): List<Map<String, Any>> {
        if (!hasPermission()) return emptyList()
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startMs, endMs)
            ?: return emptyList()
        return stats
            .filter { it.totalTimeInForeground > 0 }
            .map { stat ->
                mapOf(
                    "packageName" to stat.packageName,
                    "totalMs" to stat.totalTimeInForeground,
                    "lastUsed" to stat.lastTimeUsed,
                    "firstTime" to stat.firstTimeStamp
                )
            }
    }

    fun getPickupCount(startMs: Long, endMs: Long): Int {
        if (!hasPermission()) return 0
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usm.queryEvents(startMs, endMs) ?: return 0
        var count = 0
        var lastPkg = ""
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED && event.packageName != lastPkg) {
                count++
                lastPkg = event.packageName
            }
        }
        return count
    }

    fun getFirstPickupTime(startMs: Long, endMs: Long): Long {
        if (!hasPermission()) return -1L
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usm.queryEvents(startMs, endMs) ?: return -1L
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                return event.timeStamp
            }
        }
        return -1L
    }

    fun getLastPickupTime(startMs: Long, endMs: Long): Long {
        if (!hasPermission()) return -1L
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usm.queryEvents(startMs, endMs) ?: return -1L
        var lastTime = -1L
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                lastTime = event.timeStamp
            }
        }
        return lastTime
    }
}
