package com.digitalwellbeing.digital_wellbeing_app

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.CountDownTimer
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class BlockingActivity : Activity() {
    companion object {
        private const val TAG = "BlockingActivity"
    }

    private var countDownTimer: CountDownTimer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        try {
            Log.d(TAG, "BlockingActivity.onCreate() START")
            super.onCreate(savedInstanceState)

            window?.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
            window?.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
            window?.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            window?.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)

            val blockedPackage = intent.getStringExtra("blocked_package") ?: "Unknown"
            val appName = try {
                val pm = packageManager
                val appInfo = pm.getApplicationInfo(blockedPackage, 0)
                pm.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) {
                blockedPackage
            }

            val prefs = getSharedPreferences("enforcement_prefs", MODE_PRIVATE)
            val endTime = prefs.getString("end_time", "10:00") ?: "10:00"

            val mindfulDelayEnabled = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                .getBoolean("flutter.mindful_delay_enabled", true)

            if (mindfulDelayEnabled) {
                showDelayUI(appName, endTime)
            } else {
                showBlockingUI(appName, endTime)
            }

            Log.d(TAG, "BlockingActivity.onCreate() COMPLETE")
        } catch (e: Exception) {
            Log.e(TAG, "FATAL ERROR in BlockingActivity.onCreate(): ${e.message}", e)
            finish()
        }
    }

    private fun makeLayout(): LinearLayout = LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(64, 64, 64, 64)
        gravity = Gravity.CENTER
        setBackgroundColor(0xFFF5F5F5.toInt())
    }

    private fun showDelayUI(appName: String, endTime: String) {
        val layout = makeLayout()

        val iconText = TextView(this).apply {
            text = "🧘"
            textSize = 64f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 16)
        }

        val titleText = TextView(this).apply {
            text = "Take a Breath"
            textSize = 26f
            setTextColor(0xFF6B4FA0.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 12)
            setTypeface(null, android.graphics.Typeface.BOLD)
        }

        val appNameText = TextView(this).apply {
            text = appName
            textSize = 16f
            setTextColor(0xFF666666.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 8)
        }

        val promptText = TextView(this).apply {
            text = "Do you really need to open this right now?\nTake a moment before deciding."
            textSize = 14f
            setTextColor(0xFF888888.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
            lineHeight = (20 * resources.displayMetrics.scaledDensity).toInt()
        }

        val countdownText = TextView(this).apply {
            textSize = 64f
            gravity = Gravity.CENTER
            setTextColor(0xFF6B4FA0.toInt())
            setTypeface(null, android.graphics.Typeface.BOLD)
            setPadding(0, 0, 0, 32)
        }

        val backButton = Button(this).apply {
            text = "GO BACK"
            textSize = 16f
            setPadding(48, 24, 48, 24)
            setBackgroundColor(0xFF6B4FA0.toInt())
            setTextColor(0xFFFFFFFF.toInt())
            setOnClickListener { goHome() }
        }

        layout.addView(iconText)
        layout.addView(titleText)
        layout.addView(appNameText)
        layout.addView(promptText)
        layout.addView(countdownText)
        layout.addView(backButton)
        setContentView(layout)

        // Start 5-second countdown, then show blocking screen
        countDownTimer = object : CountDownTimer(5500, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val secs = (millisUntilFinished / 1000).toInt() + 1
                countdownText.text = "$secs"
            }

            override fun onFinish() {
                countdownText.text = "🚫"
                // Brief pause, then swap to blocking UI
                layout.postDelayed({
                    showBlockingUI(appName, endTime)
                }, 400)
            }
        }.start()
    }

    private fun showBlockingUI(appName: String, endTime: String) {
        val layout = makeLayout()

        val iconText = TextView(this).apply {
            text = "🧘"
            textSize = 64f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 24)
        }

        val titleText = TextView(this).apply {
            text = "Mindful Moment"
            textSize = 28f
            setTextColor(0xFF6B4FA0.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 16)
            setTypeface(null, android.graphics.Typeface.BOLD)
        }

        val appNameText = TextView(this).apply {
            text = appName
            textSize = 18f
            setTextColor(0xFF666666.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 8)
        }

        val messageText = TextView(this).apply {
            text = "Taking a break from this app.\nAvailable again at $endTime\n\nUse this time for something meaningful 🌟"
            textSize = 16f
            setTextColor(0xFF888888.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 48)
            lineHeight = (20 * resources.displayMetrics.scaledDensity).toInt()
        }

        val backButton = Button(this).apply {
            text = "GO BACK"
            textSize = 16f
            setPadding(48, 24, 48, 24)
            setBackgroundColor(0xFF6B4FA0.toInt())
            setTextColor(0xFFFFFFFF.toInt())
            setOnClickListener { goHome() }
        }

        layout.addView(iconText)
        layout.addView(titleText)
        layout.addView(appNameText)
        layout.addView(messageText)
        layout.addView(backButton)
        setContentView(layout)
    }

    private fun goHome() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }

    override fun onBackPressed() {
        super.onBackPressed()
        goHome()
    }

    override fun onDestroy() {
        countDownTimer?.cancel()
        super.onDestroy()
    }
}
