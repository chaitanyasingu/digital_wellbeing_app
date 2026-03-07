package com.digitalwellbeing.digital_wellbeing_app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import android.content.pm.PackageManager
import android.util.Log
import android.view.WindowManager

class BlockingActivity : Activity() {
    companion object {
        private const val TAG = "BlockingActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        try {
            Log.d(TAG, "===================== BlockingActivity.onCreate() START =====================")
            super.onCreate(savedInstanceState)
            
            // Set window flags to ensure visibility
            Log.d(TAG, "Setting window flags...")
            window?.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
            window?.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
            window?.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            window?.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
            Log.d(TAG, "Window flags set successfully")
            
            Log.d(TAG, "Creating UI layout...")
            // Create UI programmatically
            val layout = android.widget.LinearLayout(this).apply {
                orientation = android.widget.LinearLayout.VERTICAL
                setPadding(64, 64, 64, 64)
                gravity = android.view.Gravity.CENTER
                setBackgroundColor(0xFFF5F5F5.toInt())
            }
            Log.d(TAG, "Layout created successfully")

            val blockedPackage = intent.getStringExtra("blocked_package") ?: "Unknown"
            Log.d(TAG, "Blocked package: $blockedPackage")
        
        // Get app name
        val appName = try {
            Log.d(TAG, "Getting app name for $blockedPackage...")
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(blockedPackage, 0)
            val name = pm.getApplicationLabel(appInfo).toString()
            Log.d(TAG, "App name retrieved: $name")
            name
        } catch (e: Exception) {
            Log.e(TAG, "Exception getting app name: ${e.message}", e)
            blockedPackage
        }
        
        // Get next unlock time
        Log.d(TAG, "Getting unlock time from preferences...")
        val prefs = getSharedPreferences("enforcement_prefs", MODE_PRIVATE)
        val endTime = prefs.getString("end_time", "10:00") ?: "10:00"
        Log.d(TAG, "Unlock time: $endTime")

        Log.d(TAG, "Creating icon text view...")
        val iconText = TextView(this).apply {
            text = "🧘"
            textSize = 64f
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 24)
        }
        Log.d(TAG, "Icon text created")

        Log.d(TAG, "Creating title text view...")
        val titleText = TextView(this).apply {
            text = "Mindful Moment"
            textSize = 28f
            setTextColor(0xFF6B4FA0.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 16)
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        Log.d(TAG, "Title text created")

        Log.d(TAG, "Creating app name text view...")
        val appNameText = TextView(this).apply {
            text = appName
            textSize = 18f
            setTextColor(0xFF666666.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 8)
        }
        Log.d(TAG, "App name text created")

        Log.d(TAG, "Creating message text view...")
        val messageText = TextView(this).apply {
            text = "Taking a break from this app.\nAvailable again at $endTime\n\nUse this time for something meaningful 🌟"
            textSize = 16f
            setTextColor(0xFF888888.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 48)
            lineHeight = (20 * resources.displayMetrics.scaledDensity).toInt()
        }
        Log.d(TAG, "Message text created")

        Log.d(TAG, "Creating back button...")
        val backButton = Button(this).apply {
            text = "GO BACK"
            textSize = 16f
            setPadding(48, 24, 48, 24)
            setBackgroundColor(0xFF6B4FA0.toInt())
            setTextColor(0xFFFFFFFF.toInt())
            setOnClickListener {
                Log.d(TAG, "Back button clicked")
                goHome()
            }
        }
        Log.d(TAG, "Back button created")

        Log.d(TAG, "Adding views to layout...")
        layout.addView(iconText)
        layout.addView(titleText)
        layout.addView(appNameText)
        layout.addView(messageText)
        layout.addView(backButton)
        Log.d(TAG, "All views added")

        Log.d(TAG, "Setting content view...")
        setContentView(layout)
        Log.d(TAG, "Content view set successfully")
        Log.d(TAG, "===================== BlockingActivity.onCreate() COMPLETE =====================")
        
        } catch (e: Exception) {
            Log.e(TAG, "FATAL ERROR in BlockingActivity.onCreate(): ${e.message}", e)
            e.printStackTrace()
            finish()
        }
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
