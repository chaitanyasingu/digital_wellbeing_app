package com.digitalwellbeing.digital_wellbeing_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class EnforcementForegroundService : Service() {

    companion object {
        private const val TAG = "EnforcementService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "enforcement_channel"
        private const val CHANNEL_NAME = "Enforcement Active"
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Foreground service created")
        createNotificationChannel()
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
        Log.d(TAG, "Foreground service destroyed")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when app blocking is active"
            }

            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
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

        val title = if (isInRestriction) {
            "🔒 Restrictions Active"
        } else {
            "Digital Wellbeing Monitoring"
        }

        val text = if (isInRestriction) {
            "Apps restricted until $endTime"
        } else {
            "Enforcement enabled • $startTime - $endTime"
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(
                if (isInRestriction) 
                    android.R.drawable.ic_lock_idle_lock 
                else 
                    android.R.drawable.ic_dialog_info
            )
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
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
