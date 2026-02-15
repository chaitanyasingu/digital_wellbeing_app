package com.digitalwellbeing.digital_wellbeing_app

import android.app.Activity
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.*

class BlockingActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Create UI programmatically
        val layout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setPadding(48, 48, 48, 48)
            gravity = android.view.Gravity.CENTER
        }

        val blockedPackage = intent.getStringExtra("blocked_package") ?: "Unknown"
        
        // Get next unlock time
        val prefs = getSharedPreferences("enforcement_prefs", MODE_PRIVATE)
        val endTime = prefs.getString("end_time", "10:00") ?: "10:00"

        val titleText = TextView(this).apply {
            text = "App Blocked"
            textSize = 28f
            setTextColor(0xFF333333.toInt())
            gravity = android.view.Gravity.CENTER
        }

        val messageText = TextView(this).apply {
            text = "App blocked\nUnlocks at $endTime"
            textSize = 14f
            setTextColor(0xFF666666.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 24, 0, 24)
        }

        val backButton = Button(this).apply {
            text = "GO BACK"
            setOnClickListener {
                finish()
            }
        }

        layout.addView(titleText)
        layout.addView(messageText)
        layout.addView(backButton)

        setContentView(layout)
    }

    override fun onBackPressed() {
        super.onBackPressed()
        finish()
    }
}
