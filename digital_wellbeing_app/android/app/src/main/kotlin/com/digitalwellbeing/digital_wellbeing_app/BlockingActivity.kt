package com.digitalwellbeing.digital_wellbeing_app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import android.content.pm.PackageManager

class BlockingActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Create UI programmatically
        val layout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setPadding(64, 64, 64, 64)
            gravity = android.view.Gravity.CENTER
            setBackgroundColor(0xFFF5F5F5.toInt())
        }

        val blockedPackage = intent.getStringExtra("blocked_package") ?: "Unknown"
        
        // Get app name
        val appName = try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(blockedPackage, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            blockedPackage
        }
        
        // Get next unlock time
        val prefs = getSharedPreferences("enforcement_prefs", MODE_PRIVATE)
        val endTime = prefs.getString("end_time", "10:00") ?: "10:00"

        // Icon
        val iconText = TextView(this).apply {
            text = "🧘"
            textSize = 64f
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 24)
        }

        val titleText = TextView(this).apply {
            text = "Mindful Moment"
            textSize = 28f
            setTextColor(0xFF6B4FA0.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 16)
            setTypeface(null, android.graphics.Typeface.BOLD)
        }

        val appNameText = TextView(this).apply {
            text = appName
            textSize = 18f
            setTextColor(0xFF666666.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 8)
        }

        val messageText = TextView(this).apply {
            text = "Taking a break from this app.\nAvailable again at $endTime\n\nUse this time for something meaningful 🌟"
            textSize = 16f
            setTextColor(0xFF888888.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 48)
            lineHeight = (20 * resources.displayMetrics.scaledDensity).toInt()
        }

        val backButton = Button(this).apply {
            text = "GO BACK"
            textSize = 16f
            setPadding(48, 24, 48, 24)
            setBackgroundColor(0xFF6B4FA0.toInt())
            setTextColor(0xFFFFFFFF.toInt())
            setOnClickListener {
                goHome()
            }
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
}
