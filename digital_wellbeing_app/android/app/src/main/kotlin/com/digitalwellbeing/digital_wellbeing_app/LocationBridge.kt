package com.digitalwellbeing.digital_wellbeing_app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Build
import androidx.core.content.ContextCompat

class LocationBridge(private val context: Context) {

    private val locationManager: LocationManager =
        context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

    fun hasPermission(): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED

    fun hasBackgroundPermission(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
            ContextCompat.checkSelfPermission(
                context, Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        else
            hasPermission()

    fun getLastKnownLocation(): Map<String, Double>? {
        if (!hasPermission()) return null
        return try {
            val providers = listOf(
                LocationManager.GPS_PROVIDER,
                LocationManager.NETWORK_PROVIDER,
                LocationManager.PASSIVE_PROVIDER
            )
            var best: Location? = null
            for (provider in providers) {
                try {
                    if (!locationManager.isProviderEnabled(provider)) continue
                    val loc = locationManager.getLastKnownLocation(provider) ?: continue
                    if (best == null || loc.accuracy < best.accuracy) best = loc
                } catch (_: Exception) {}
            }
            best?.let {
                mapOf(
                    "lat" to it.latitude,
                    "lng" to it.longitude,
                    "accuracy" to it.accuracy.toDouble()
                )
            }
        } catch (e: Exception) {
            null
        }
    }
}
