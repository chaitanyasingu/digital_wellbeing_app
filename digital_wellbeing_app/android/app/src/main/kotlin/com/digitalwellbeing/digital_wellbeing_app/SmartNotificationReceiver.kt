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
import java.util.Calendar

class SmartNotificationReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "SmartNotifReceiver"
        const val CHANNEL_ID = "smart_notifications"
        const val EXTRA_TYPE = "notification_type"
        const val EXTRA_HOUR = "hour"
        const val EXTRA_MINUTE = "minute"

        const val TYPE_MORNING = "morning_intention"
        const val TYPE_EVENING = "evening_winddown"
        const val TYPE_DAILY_SUMMARY = "daily_summary"

        private const val ID_MORNING = 2001
        private const val ID_EVENING = 2002
        private const val ID_SUMMARY = 2003

        private const val PREFS_NAME = "notification_prefs"

        fun schedule(context: Context, type: String, hour: Int, minute: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().apply {
                putBoolean("${type}_enabled", true)
                putInt("${type}_hour", hour)
                putInt("${type}_minute", minute)
                apply()
            }
            scheduleAlarm(context, type, hour, minute)
        }

        private fun scheduleAlarm(context: Context, type: String, hour: Int, minute: Int) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, SmartNotificationReceiver::class.java).apply {
                putExtra(EXTRA_TYPE, type)
                putExtra(EXTRA_HOUR, hour)
                putExtra(EXTRA_MINUTE, minute)
            }
            val pi = PendingIntent.getBroadcast(
                context,
                requestCodeFor(type),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val cal = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pi)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pi)
            }
            Log.d(TAG, "Scheduled $type at $hour:$minute")
        }

        fun cancel(context: Context, type: String) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putBoolean("${type}_enabled", false).apply()
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, SmartNotificationReceiver::class.java)
            val pi = PendingIntent.getBroadcast(
                context,
                requestCodeFor(type),
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            pi?.let { alarmManager.cancel(it) }
            Log.d(TAG, "Cancelled $type")
        }

        fun rescheduleFromPrefs(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            listOf(TYPE_MORNING, TYPE_EVENING, TYPE_DAILY_SUMMARY).forEach { type ->
                if (prefs.getBoolean("${type}_enabled", false)) {
                    val hour = prefs.getInt("${type}_hour", defaultHourFor(type))
                    val minute = prefs.getInt("${type}_minute", defaultMinuteFor(type))
                    scheduleAlarm(context, type, hour, minute)
                }
            }
        }

        private fun defaultHourFor(type: String) = when (type) {
            TYPE_MORNING -> 8
            TYPE_EVENING -> 21
            TYPE_DAILY_SUMMARY -> 21
            else -> 8
        }

        private fun defaultMinuteFor(type: String) = when (type) {
            TYPE_DAILY_SUMMARY -> 30
            else -> 0
        }

        private fun requestCodeFor(type: String) = when (type) {
            TYPE_MORNING -> ID_MORNING
            TYPE_EVENING -> ID_EVENING
            TYPE_DAILY_SUMMARY -> ID_SUMMARY
            else -> 2099
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val type = intent.getStringExtra(EXTRA_TYPE) ?: return
        val hour = intent.getIntExtra(EXTRA_HOUR, 8)
        val minute = intent.getIntExtra(EXTRA_MINUTE, 0)

        createChannel(context)

        val (title, message, notifId) = when (type) {
            TYPE_MORNING -> Triple(
                "Good morning! 🌅",
                "What's your focus for today? Set an intention before picking up your phone.",
                ID_MORNING
            )
            TYPE_EVENING -> Triple(
                "Wind down time 🌙",
                "Time to put the phone down and prepare for a restful night.",
                ID_EVENING
            )
            TYPE_DAILY_SUMMARY -> Triple(
                "Your daily summary 📊",
                "Tap to see how your screen time looks today.",
                ID_SUMMARY
            )
            else -> return
        }

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pi = PendingIntent.getActivity(
            context, notifId, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setContentIntent(pi)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        nm.notify(notifId, notification)
        Log.d(TAG, "Showed notification for $type")

        // Reschedule for tomorrow
        scheduleAlarm(context, type, hour, minute)
    }

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (nm.getNotificationChannel(CHANNEL_ID) != null) return
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Mindfulness Reminders",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply { description = "Daily mindfulness and screen time reminders" }
            nm.createNotificationChannel(channel)
        }
    }
}
