package com.digitalwellbeing.digital_wellbeing_app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.Build
import androidx.core.content.ContextCompat

class WifiBridge(private val context: Context) {

    private val wifiManager: WifiManager =
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

    fun hasPermission(): Boolean {
        val perm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
            Manifest.permission.ACCESS_FINE_LOCATION
        else
            Manifest.permission.ACCESS_COARSE_LOCATION
        return ContextCompat.checkSelfPermission(context, perm) ==
                PackageManager.PERMISSION_GRANTED
    }

    fun getCurrentSsid(): String? {
        return try {
            if (!hasPermission()) return null
            if (!wifiManager.isWifiEnabled) return null
            val info = wifiManager.connectionInfo ?: return null
            val ssid = info.ssid ?: return null
            if (ssid == "<unknown ssid>" || ssid.isBlank()) return null
            ssid.trim('"')
        } catch (e: Exception) {
            null
        }
    }

    fun isWifiEnabled(): Boolean = try { wifiManager.isWifiEnabled } catch (e: Exception) { false }
}
