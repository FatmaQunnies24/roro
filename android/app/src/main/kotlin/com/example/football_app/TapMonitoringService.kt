package com.example.football_app

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.content.SharedPreferences
import android.content.Context
import android.util.Log

class TapMonitoringService : AccessibilityService() {
    private val TAG = "TapMonitoringService"
    private val PREFS_NAME = "FlutterSharedPreferences"
    private val KEY_PERMISSION_REQUESTED = "flutter.accessibility_permission_requested"
    
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.let {
            // عد الأحداث التي تشير إلى الضغطات في جميع التطبيقات
            when (it.eventType) {
                AccessibilityEvent.TYPE_VIEW_CLICKED,
                AccessibilityEvent.TYPE_VIEW_LONG_CLICKED,
                AccessibilityEvent.TYPE_VIEW_SELECTED -> {
                    val packageName = it.packageName?.toString() ?: "unknown"
                    val appPackageName = applicationContext.packageName
                    
                    // التحقق من أن الضغطة في تطبيق آخر (ليس تطبيقنا)
                    if (packageName != appPackageName && packageName != "unknown") {
                        // التحقق من أننا لم نطلب الإذن من قبل
                        val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        val permissionRequested = prefs.getBoolean(KEY_PERMISSION_REQUESTED, false)
                        
                        if (!permissionRequested) {
                            // طلب الإذن لأول مرة عند اكتشاف ضغطة في تطبيق آخر
                            Log.d(TAG, "تم اكتشاف ضغطة في تطبيق آخر ($packageName) - طلب الإذن")
                            prefs.edit().putBoolean(KEY_PERMISSION_REQUESTED, true).apply()
                            
                            // إرسال إشعار لطلب الإذن (سيتم التعامل معه في Flutter)
                            requestAccessibilityPermission()
                        }
                        
                        // زيادة عدد الضغطات (يعمل حتى في التطبيقات الأخرى)
                        incrementTapCount(this, packageName)
                        Log.d(TAG, "تم اكتشاف ضغطة في ${packageName} - العدد الجديد: ${getTapCount(this)}")
                    } else {
                        // تجاهل الضغطات داخل تطبيقنا
                        Log.d(TAG, "تم تجاهل ضغطة داخل التطبيق ($packageName)")
                    }
                }
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                    // عند تغيير النافذة (فتح تطبيق جديد)
                    val packageName = it.packageName?.toString() ?: "unknown"
                    val appPackageName = applicationContext.packageName
                    
                    if (packageName != appPackageName && packageName != "unknown") {
                        Log.d(TAG, "تم تغيير النافذة إلى تطبيق آخر: ${packageName}")
                    } else {
                        Log.d(TAG, "تم تغيير النافذة إلى: ${packageName}")
                    }
                }
                else -> {
                    // تجاهل الأحداث الأخرى
                }
            }
        }
    }
    
    private fun requestAccessibilityPermission() {
        // حفظ flag في SharedPreferences لإعلام Flutter بطلب الإذن
        val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.should_request_accessibility", true).apply()
        Log.d(TAG, "تم تعيين flag لطلب إذن Accessibility في Flutter")
    }

    override fun onInterrupt() {
        Log.d(TAG, "تمت مقاطعة الخدمة")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "تم تفعيل خدمة المراقبة - جاهزة لعد الضغطات في جميع التطبيقات")
        
        // إرسال إشعار أن الخدمة جاهزة
        val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.accessibility_service_ready", true).apply()
    }

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_TAP_COUNT = "flutter.monitoring_tapCount"
        
        fun incrementTapCount(context: Context, packageName: String = "unknown") {
            try {
                // استخدام نفس SharedPreferences التي يستخدمها Flutter
                val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                
                // محاولة قراءة القيمة كـ Int أولاً (Flutter يحفظ Int كـ Long)
                val currentCount = try {
                    // Flutter يحفظ Int كـ Long في SharedPreferences
                    val longValue = prefs.getLong(KEY_TAP_COUNT, -1L)
                    if (longValue >= 0) {
                        longValue.toInt()
                    } else {
                        // إذا لم تكن موجودة كـ Long، جرب String
                        val stringValue = prefs.getString(KEY_TAP_COUNT, "0")
                        stringValue?.toIntOrNull() ?: 0
                    }
                } catch (e: Exception) {
                    // إذا فشل، جرب String
                    try {
                        val stringValue = prefs.getString(KEY_TAP_COUNT, "0")
                        stringValue?.toIntOrNull() ?: 0
                    } catch (e2: Exception) {
                        0
                    }
                }
                
                val newCount = currentCount + 1
                // حفظ كـ Int (سيتم حفظه كـ Long تلقائياً)
                prefs.edit().putInt(KEY_TAP_COUNT, newCount).apply()
                Log.d("TapMonitoringService", "تم زيادة الضغطات: $newCount (من $packageName)")
            } catch (e: Exception) {
                Log.e("TapMonitoringService", "خطأ في حفظ الضغطات: ${e.message}")
            }
        }
        
        fun getTapCount(context: Context): Int {
            val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return try {
                // محاولة قراءة القيمة كـ Int أولاً (Flutter يحفظ Int كـ Long)
                val longValue = prefs.getLong(KEY_TAP_COUNT, -1L)
                if (longValue >= 0) {
                    longValue.toInt()
                } else {
                    // إذا لم تكن موجودة كـ Long، جرب String
                    val stringValue = prefs.getString(KEY_TAP_COUNT, "0")
                    stringValue?.toIntOrNull() ?: 0
                }
            } catch (e: Exception) {
                // إذا فشل، جرب String
                try {
                    val stringValue = prefs.getString(KEY_TAP_COUNT, "0")
                    stringValue?.toIntOrNull() ?: 0
                } catch (e2: Exception) {
                    0
                }
            }
        }
    }
}

