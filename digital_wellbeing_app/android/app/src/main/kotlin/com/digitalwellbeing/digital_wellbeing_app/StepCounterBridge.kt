package com.digitalwellbeing.digital_wellbeing_app

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class StepCounterBridge(private val context: Context) {

    companion object {
        private const val TAG = "StepCounterBridge"
        private const val PREFS_NAME = "step_counter_prefs"
        private const val PREF_BASELINE_DATE = "baseline_date"
        private const val PREF_BASELINE_STEPS = "baseline_steps"
        private const val SENSOR_TIMEOUT_MS = 2000L
        const val PERMISSION_REQUEST_CODE = 200
    }

    fun isAvailable(): Boolean {
        val sm = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        return sm.getDefaultSensor(Sensor.TYPE_STEP_COUNTER) != null
    }

    fun hasPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            context.checkSelfPermission(android.Manifest.permission.ACTIVITY_RECOGNITION) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    fun requestPermission(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(android.Manifest.permission.ACTIVITY_RECOGNITION),
                PERMISSION_REQUEST_CODE
            )
        }
    }

    // Async: fires callback with today's step count, or -1 on timeout/unavailable.
    fun getStepsToday(callback: (Int) -> Unit) {
        if (!hasPermission() || !isAvailable()) {
            callback(-1)
            return
        }

        val sm = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensor = sm.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        if (sensor == null) {
            callback(-1)
            return
        }

        val mainHandler = Handler(Looper.getMainLooper())
        var fired = false

        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent?) {
                if (fired) return
                fired = true
                event ?: run { callback(-1); return }

                val totalSteps = event.values[0].toLong()
                sm.unregisterListener(this)

                val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val savedDate = prefs.getString(PREF_BASELINE_DATE, "")

                val baseline: Long = if (savedDate != today) {
                    // New day — reset baseline
                    prefs.edit().apply {
                        putString(PREF_BASELINE_DATE, today)
                        putLong(PREF_BASELINE_STEPS, totalSteps)
                        apply()
                    }
                    totalSteps
                } else {
                    prefs.getLong(PREF_BASELINE_STEPS, totalSteps)
                }

                val todaySteps = maxOf(0L, totalSteps - baseline).toInt()
                Log.d(TAG, "Steps today: $todaySteps (total=$totalSteps, baseline=$baseline)")
                mainHandler.post { callback(todaySteps) }
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }

        sm.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_FASTEST, mainHandler)

        // Timeout fallback
        mainHandler.postDelayed({
            if (!fired) {
                fired = true
                sm.unregisterListener(listener)
                Log.w(TAG, "Step sensor timeout")
                callback(-1)
            }
        }, SENSOR_TIMEOUT_MS)
    }
}
