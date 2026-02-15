package com.digitalwellbeing.digital_wellbeing_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootCompletedReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Device boot completed")

            // Check if enforcement was enabled before reboot
            val prefs = context.getSharedPreferences("enforcement_prefs", Context.MODE_PRIVATE)
            val enforcementEnabled = prefs.getBoolean("enforcement_enabled", false)

            if (enforcementEnabled) {
                Log.d(TAG, "Restarting enforcement after reboot")
                
                // Start foreground service
                val serviceIntent = Intent(context, EnforcementForegroundService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        }
    }
}
