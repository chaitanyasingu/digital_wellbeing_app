package com.digitalwellbeing.digital_wellbeing_app

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent

class DeviceAdminBridge(private val context: Context) {

    private val dpm: DevicePolicyManager =
        context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager

    val adminComponent: ComponentName =
        ComponentName(context, AppDeviceAdminReceiver::class.java)

    fun isAdminActive(): Boolean = dpm.isAdminActive(adminComponent)

    fun buildActivateIntent(): Intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
        putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
        putExtra(
            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
            "Prevents Digital Mindfulness from being uninstalled while restrictions are active."
        )
    }

    fun deactivate() {
        dpm.removeActiveAdmin(adminComponent)
    }
}
