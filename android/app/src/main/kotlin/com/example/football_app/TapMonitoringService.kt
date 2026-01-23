package com.example.football_app

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.content.SharedPreferences
import android.content.Context

class TapMonitoringService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // هذا المكان يمكن استخدامه لعد الأحداث
        // لكن للبساطة، سنستخدم طريقة أخرى
    }

    override fun onInterrupt() {
        // لا شيء
    }

    companion object {
        fun incrementTapCount(context: Context) {
            val prefs: SharedPreferences = context.getSharedPreferences("monitoring_prefs", Context.MODE_PRIVATE)
            val currentCount = prefs.getInt("monitoring_tapCount", 0)
            prefs.edit().putInt("monitoring_tapCount", currentCount + 1).apply()
        }
    }
}

