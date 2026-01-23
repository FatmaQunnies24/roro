package com.example.football_app

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.content.SharedPreferences
import android.content.Context
import android.util.Log

class TapMonitoringService : AccessibilityService() {
    private val TAG = "TapMonitoringService"
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.let {
            // عد الأحداث التي تشير إلى الضغطات في جميع التطبيقات
            when (it.eventType) {
                AccessibilityEvent.TYPE_VIEW_CLICKED,
                AccessibilityEvent.TYPE_VIEW_LONG_CLICKED,
                AccessibilityEvent.TYPE_VIEW_SELECTED -> {
                    // زيادة عدد الضغطات (يعمل حتى في التطبيقات الأخرى)
                    incrementTapCount(this, it.packageName?.toString() ?: "unknown")
                    Log.d(TAG, "تم اكتشاف ضغطة في ${it.packageName} - العدد الجديد: ${getTapCount(this)}")
                }
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                    // عند تغيير النافذة (فتح تطبيق جديد)
                    Log.d(TAG, "تم تغيير النافذة إلى: ${it.packageName}")
                }
                else -> {
                    // تجاهل الأحداث الأخرى
                }
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "تمت مقاطعة الخدمة")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "تم تفعيل خدمة المراقبة")
    }

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_TAP_COUNT = "flutter.monitoring_tapCount"
        
        fun incrementTapCount(context: Context, packageName: String = "unknown") {
            try {
                // استخدام نفس SharedPreferences التي يستخدمها Flutter
                val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val currentCountStr = prefs.getString(KEY_TAP_COUNT, "0")
                val currentCount = try {
                    currentCountStr?.toInt() ?: 0
                } catch (e: Exception) {
                    0
                }
                val newCount = currentCount + 1
                prefs.edit().putString(KEY_TAP_COUNT, newCount.toString()).apply()
                Log.d("TapMonitoringService", "تم زيادة الضغطات: $newCount (من $packageName)")
            } catch (e: Exception) {
                Log.e("TapMonitoringService", "خطأ في حفظ الضغطات: ${e.message}")
            }
        }
        
        fun getTapCount(context: Context): Int {
            val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val countStr = prefs.getString(KEY_TAP_COUNT, "0")
            return try {
                countStr?.toInt() ?: 0
            } catch (e: Exception) {
                0
            }
        }
    }
}

