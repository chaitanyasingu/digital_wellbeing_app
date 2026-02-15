package com.digitalwellbeing.digital_wellbeing_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat

class EnforcementForegroundService : Service() {

    companion object {
        private const val TAG = "EnforcementService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID_MONITORING = "enforcement_monitoring"
        private const val CHANNEL_ID_RESTRICTION = "enforcement_restriction"
        private const val CHANNEL_NAME_MONITORING = "Monitoring"
        private const val CHANNEL_NAME_RESTRICTION = "Active Restriction"
        private const val UPDATE_INTERVAL_MS = 60000L // Update every minute
    }

    private val handler = Handler(Looper.getMainLooper())
    private var updateRunnable: Runnable? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Foreground service created")
        createNotificationChannels()
        startNotificationUpdates()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Foreground service started")
        
        // Must call startForeground() immediately to avoid crash
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // Check if enforcement is actually enabled
        val prefs = getSharedPreferences("enforcement_prefs", MODE_PRIVATE)
        val enforcementEnabled = prefs.getBoolean("enforcement_enabled", false)
        
        if (!enforcementEnabled) {
            Log.d(TAG, "Enforcement not enabled, stopping service")
            stopSelf()
            return START_NOT_STICKY
        }
        
        // Return START_STICKY to auto-restart if killed (only when enabled)
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        stopNotificationUpdates()
        Log.d(TAG, "Foreground service destroyed")
    }

    private fun startNotificationUpdates() {
        updateRunnable = object : Runnable {
            override fun run() {
                updateNotification()
                handler.postDelayed(this, UPDATE_INTERVAL_MS)
            }
        }
        handler.post(updateRunnable!!)
    }

    private fun stopNotificationUpdates() {
        updateRunnable?.let { handler.removeCallbacks(it) }
    }

    private fun updateNotification() {
        val notification = createNotification()
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Low priority channel for monitoring
            val monitoringChannel = NotificationChannel(
                CHANNEL_ID_MONITORING,
                CHANNEL_NAME_MONITORING,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when monitoring is active"
                setShowBadge(false)
            }

            // High priority channel for active restrictions
            val restrictionChannel = NotificationChannel(
                CHANNEL_ID_RESTRICTION,
                CHANNEL_NAME_RESTRICTION,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Shows when restrictions are actively enforced"
                setShowBadge(true)
                enableVibration(false)
            }

            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(monitoringChannel)
            notificationManager.createNotificationChannel(restrictionChannel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE
        )

        // Get current restriction status
        val prefs = getSharedPreferences("enforcement_prefs", MODE_PRIVATE)
        val startTime = prefs.getString("start_time", "21:00") ?: "21:00"
        val endTime = prefs.getString("end_time", "10:00") ?: "10:00"
        val isInRestriction = isCurrentTimeRestricted(startTime, endTime)

        // Use different channel based on restriction status
        val channelId = if (isInRestriction) CHANNEL_ID_RESTRICTION else CHANNEL_ID_MONITORING
        val priority = if (isInRestriction) NotificationCompat.PRIORITY_HIGH else NotificationCompat.PRIORITY_LOW

        val title = if (isInRestriction) {
            "🧘 Mindful Time Active"
        } else {
            "Digital Mindfulness Active"
        }

        val text = if (isInRestriction) {
            "Taking a break from apps until $endTime"
        } else {
            "Monitoring • Restrictions: $startTime - $endTime"
        }

        val bigText = if (isInRestriction) {
            "You're in a mindful period. Only essential apps are available until $endTime. Stay focused! 🌟"
        } else {
            "Digital Mindfulness is monitoring your apps. Restrictions will activate during $startTime - $endTime."
        }

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(bigText))
            .setSmallIcon(
                if (isInRestriction) 
                    android.R.drawable.ic_lock_idle_lock 
                else 
                    android.R.drawable.ic_dialog_info
            )
            .setContentIntent(pendingIntent)
            .setOngoing(isInRestriction) // Can't dismiss during restriction
            .setPriority(priority)
            .setColor(if (isInRestriction) 0xFF6B4FA0.toInt() else 0xFF8B75B8.toInt())
            .build()
    }

    private fun isCurrentTimeRestricted(startTime: String, endTime: String): Boolean {
        try {
            val timeFormat = java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault())
            val now = java.util.Calendar.getInstance()
            val currentMinutes = now.get(java.util.Calendar.HOUR_OF_DAY) * 60 + now.get(java.util.Calendar.MINUTE)
            
            val start = timeFormat.parse(startTime)
            val startCal = java.util.Calendar.getInstance().apply { time = start!! }
            val startMinutes = startCal.get(java.util.Calendar.HOUR_OF_DAY) * 60 + startCal.get(java.util.Calendar.MINUTE)
            
            val end = timeFormat.parse(endTime)
            val endCal = java.util.Calendar.getInstance().apply { time = end!! }
            val endMinutes = endCal.get(java.util.Calendar.HOUR_OF_DAY) * 60 + endCal.get(java.util.Calendar.MINUTE)
            
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
}
