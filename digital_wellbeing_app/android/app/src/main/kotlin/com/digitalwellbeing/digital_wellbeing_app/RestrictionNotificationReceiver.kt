package com.digitalwellbeing.digital_wellbeing_app

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.*

class RestrictionNotificationReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "RestrictionNotif"
        private const val NOTIFICATION_ID = 2001
        private const val CHANNEL_ID = "restriction_alerts"
        private const val CHANNEL_NAME = "Restriction Alerts"
        private const val ACTION_RESTRICTION_START = "com.digitalwellbeing.RESTRICTION_START"
        private const val ACTION_RESTRICTION_END = "com.digitalwellbeing.RESTRICTION_END"

        fun scheduleRestrictionAlerts(context: Context, startTime: String, endTime: String) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            // Schedule start notification
            scheduleNotification(context, alarmManager, startTime, ACTION_RESTRICTION_START)
            
            // Schedule end notification
            scheduleNotification(context, alarmManager, endTime, ACTION_RESTRICTION_END)
            
            Log.d(TAG, "Scheduled restriction alerts for $startTime - $endTime")
        }

        private fun scheduleNotification(
            context: Context,
            alarmManager: AlarmManager,
            time: String,
            action: String
        ) {
            try {
                val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
                val parsedTime = timeFormat.parse(time) ?: return
                
                val calendar = Calendar.getInstance().apply {
                    val now = Calendar.getInstance()
                    set(Calendar.HOUR_OF_DAY, parsedTime.hours)
                    set(Calendar.MINUTE, parsedTime.minutes)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                    
                    // If time has passed today, schedule for tomorrow
                    if (before(now)) {
                        add(Calendar.DAY_OF_YEAR, 1)
                    }
                }

                val intent = Intent(context, RestrictionNotificationReceiver::class.java).apply {
                    this.action = action
                    putExtra("time", time)
                }

                val requestCode = if (action == ACTION_RESTRICTION_START) 1001 else 1002
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    requestCode,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                // Use setRepeating for daily notifications
                alarmManager.setRepeating(
                    AlarmManager.RTC_WAKEUP,
                    calendar.timeInMillis,
                    AlarmManager.INTERVAL_DAY,
                    pendingIntent
                )

                Log.d(TAG, "Scheduled $action notification for ${calendar.time}")
            } catch (e: Exception) {
                Log.e(TAG, "Error scheduling notification for $time", e)
            }
        }

        fun cancelRestrictionAlerts(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            // Cancel start notification
            val startIntent = Intent(context, RestrictionNotificationReceiver::class.java).apply {
                action = ACTION_RESTRICTION_START
            }
            val startPendingIntent = PendingIntent.getBroadcast(
                context, 1001, startIntent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (startPendingIntent != null) {
                alarmManager.cancel(startPendingIntent)
                startPendingIntent.cancel()
            }

            // Cancel end notification
            val endIntent = Intent(context, RestrictionNotificationReceiver::class.java).apply {
                action = ACTION_RESTRICTION_END
            }
            val endPendingIntent = PendingIntent.getBroadcast(
                context, 1002, endIntent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (endPendingIntent != null) {
                alarmManager.cancel(endPendingIntent)
                endPendingIntent.cancel()
            }

            Log.d(TAG, "Cancelled restriction alerts")
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received broadcast: ${intent.action}")
        
        when (intent.action) {
            ACTION_RESTRICTION_START -> {
                showRestrictionStartNotification(context)
            }
            ACTION_RESTRICTION_END -> {
                showRestrictionEndNotification(context)
            }
        }
    }

    fun showRestrictionStartNotification(context: Context) {
        createNotificationChannel(context)
        
        val prefs = context.getSharedPreferences("enforcement_prefs", Context.MODE_PRIVATE)
        val endTime = prefs.getString("end_time", "10:00") ?: "10:00"
        val enforcementEnabled = prefs.getBoolean("enforcement_enabled", false)
        
        if (!enforcementEnabled) {
            Log.d(TAG, "Enforcement disabled, skipping notification")
            return
        }

        val mainIntent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            mainIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("🔒 Digital Wellbeing Active")
            .setContentText("Restriction period started until $endTime")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setVibrate(longArrayOf(0, 500, 200, 500))
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("Apps are now restricted until $endTime. Only allowed apps can be opened.")
            )
            .build()

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
        
        Log.d(TAG, "Showed restriction start notification")
    }

    private fun showRestrictionEndNotification(context: Context) {
        createNotificationChannel(context)
        
        val prefs = context.getSharedPreferences("enforcement_prefs", Context.MODE_PRIVATE)
        val enforcementEnabled = prefs.getBoolean("enforcement_enabled", false)
        
        if (!enforcementEnabled) {
            return
        }

        val mainIntent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            mainIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("✅ Restriction Period Ended")
            .setContentText("You can now access all apps")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
        
        Log.d(TAG, "Showed restriction end notification")
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts when restriction periods start and end"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500)
            }

            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
