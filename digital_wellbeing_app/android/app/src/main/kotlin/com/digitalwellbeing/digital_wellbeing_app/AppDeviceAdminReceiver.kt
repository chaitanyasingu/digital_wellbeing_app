package com.digitalwellbeing.digital_wellbeing_app

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AppDeviceAdminReceiver : DeviceAdminReceiver() {

    companion object {
        private const val TAG = "DeviceAdminReceiver"
    }

    override fun onEnabled(context: Context, intent: Intent) {
        Log.d(TAG, "Device admin enabled — uninstall protection active")
    }

    override fun onDisabled(context: Context, intent: Intent) {
        Log.d(TAG, "Device admin disabled — uninstall protection removed")
    }

    override fun onPasswordExpired(context: Context, intent: Intent) {}
    override fun onPasswordChanged(context: Context, intent: Intent) {}
}
