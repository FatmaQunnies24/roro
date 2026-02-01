package com.example.football_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityEvent
import android.content.SharedPreferences
import android.content.Context
import android.util.Log

class TapMonitoringService : AccessibilityService() {
    private val TAG = "TapMonitoringService"
    private val PREFS_NAME = "FlutterSharedPreferences"
    private val KEY_PERMISSION_REQUESTED = "flutter.accessibility_permission_requested"
    private val KEY_LAST_TAP_PACKAGE = "flutter.last_tap_package"
    private val KEY_LAST_TAP_TIME = "flutter.last_tap_time"
    private val MIN_TAP_INTERVAL_MS = 300L // تقليل العد المزدوج لأحداث التركيز
    private val MIN_CONTENT_CHANGED_INTERVAL_MS = 1200L // تخفيف قوي لتغيّر المحتوى (ألعاب/واجهات مخصصة)

    private fun handleTapFromOtherApp(packageName: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val appPackageName = applicationContext.packageName
        if (packageName != appPackageName) {
            if (!prefs.getBoolean(KEY_PERMISSION_REQUESTED, false)) {
                Log.d(TAG, "تم اكتشاف ضغطة في تطبيق آخر ($packageName) - طلب الإذن")
                prefs.edit().putBoolean(KEY_PERMISSION_REQUESTED, true).apply()
                requestAccessibilityPermission()
            }
        }
        // تخفيف لأحداث TYPE_VIEW_FOCUSED: لا نعد إذا كانت آخر ضغطة من نفس التطبيق منذ أقل من MIN_TAP_INTERVAL_MS
        val lastTimeStr = prefs.getString(KEY_LAST_TAP_TIME, "0") ?: "0"
        val lastTime = lastTimeStr.toLongOrNull() ?: 0L
        if (lastTime > 0 && (System.currentTimeMillis() - lastTime) < MIN_TAP_INTERVAL_MS) {
            val lastPkg = prefs.getString(KEY_LAST_TAP_PACKAGE, "")
            if (packageName == lastPkg) return
        }
        incrementTapCount(this, packageName)
        prefs.edit()
            .putString(KEY_LAST_TAP_PACKAGE, packageName)
            .putString(KEY_LAST_TAP_TIME, System.currentTimeMillis().toString())
            .apply()
        Log.d(TAG, "ضغطة من $packageName - العدد: ${getTapCount(this)}")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event?.let {
            when (it.eventType) {
                AccessibilityEvent.TYPE_VIEW_CLICKED,
                AccessibilityEvent.TYPE_VIEW_LONG_CLICKED,
                AccessibilityEvent.TYPE_VIEW_SELECTED -> {
                    val packageName = it.packageName?.toString() ?: "other"
                    val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    if (packageName != applicationContext.packageName) {
                        if (!prefs.getBoolean(KEY_PERMISSION_REQUESTED, false)) {
                            Log.d(TAG, "تم اكتشاف ضغطة في تطبيق آخر ($packageName) - طلب الإذن")
                            prefs.edit().putBoolean(KEY_PERMISSION_REQUESTED, true).apply()
                            requestAccessibilityPermission()
                        }
                    }
                    // عد كل الضغطات — داخل التطبيق وخارجه
                    incrementTapCount(this, packageName)
                    prefs.edit()
                        .putString(KEY_LAST_TAP_PACKAGE, packageName)
                        .putString(KEY_LAST_TAP_TIME, System.currentTimeMillis().toString())
                        .apply()
                    Log.d(TAG, "ضغطة من $packageName - العدد: ${getTapCount(this)}")
                }
                AccessibilityEvent.TYPE_VIEW_FOCUSED -> {
                    val packageName = it.packageName?.toString() ?: "other"
                    handleTapFromOtherApp(packageName)
                }
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                    // ألعاب/تطبيقات بواجهة مخصصة لا ترسل ضغط أو تركيز — نعد تغيّر المحتوى بتخفيف قوي (تقديري)
                    val packageName = it.packageName?.toString() ?: "other"
                    if (packageName == applicationContext.packageName) return@let
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    val lastTimeStr = prefs.getString(KEY_LAST_TAP_TIME, "0") ?: "0"
                    val lastTime = lastTimeStr.toLongOrNull() ?: 0L
                    if (lastTime > 0 && (System.currentTimeMillis() - lastTime) < MIN_CONTENT_CHANGED_INTERVAL_MS) {
                        val lastPkg = prefs.getString(KEY_LAST_TAP_PACKAGE, "")
                        if (packageName == lastPkg) return@let
                    }
                    if (!prefs.getBoolean(KEY_PERMISSION_REQUESTED, false)) {
                        prefs.edit().putBoolean(KEY_PERMISSION_REQUESTED, true).apply()
                        requestAccessibilityPermission()
                    }
                    incrementTapCount(this, packageName)
                    prefs.edit()
                        .putString(KEY_LAST_TAP_PACKAGE, packageName)
                        .putString(KEY_LAST_TAP_TIME, System.currentTimeMillis().toString())
                        .apply()
                    Log.d(TAG, "تغيّر محتوى (تقديري) من $packageName - العدد: ${getTapCount(this)}")
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
        // ضبط الخدمة لاستقبال الأحداث من كل التطبيقات (بدون تصفية حسب الحزمة)
        try {
            val info = serviceInfo ?: AccessibilityServiceInfo()
            info.packageNames = null
            info.eventTypes = AccessibilityEvent.TYPE_VIEW_CLICKED or
                AccessibilityEvent.TYPE_VIEW_LONG_CLICKED or
                AccessibilityEvent.TYPE_VIEW_SELECTED or
                AccessibilityEvent.TYPE_VIEW_FOCUSED or
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            val newFlags = info.flags or
                AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            info.flags = newFlags
            info.notificationTimeout = 100
            setServiceInfo(info)
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في ضبط خدمة إمكانية الوصول: ${e.message}")
        }
        Log.d(TAG, "تم تفعيل خدمة المراقبة - جاهزة لعد الضغطات في جميع التطبيقات")
        
        val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.accessibility_service_ready", true).apply()
    }

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_TAP_COUNT = "flutter.monitoring_tapCount"
        
        fun incrementTapCount(context: Context, packageName: String = "unknown") {
            try {
                // استخدام نفس SharedPreferences التي يستخدمها Flutter (المفتاح مع بادئة flutter.)
                val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                
                // قراءة العدد الحالي - Flutter يحفظ بـ setInt('monitoring_tapCount') = flutter.monitoring_tapCount
                val currentCount = try {
                    prefs.getInt(KEY_TAP_COUNT, -1).let { if (it >= 0) it else 0 }
                } catch (e: Exception) {
                    try {
                        prefs.getString(KEY_TAP_COUNT, "0")?.toIntOrNull() ?: 0
                    } catch (e2: Exception) {
                        0
                    }
                }
                
                val newCount = currentCount + 1
                prefs.edit().putInt(KEY_TAP_COUNT, newCount).apply()
                Log.d("TapMonitoringService", "تم زيادة الضغطات: $newCount (من $packageName)")
            } catch (e: Exception) {
                Log.e("TapMonitoringService", "خطأ في حفظ الضغطات: ${e.message}")
            }
        }
        
        fun getTapCount(context: Context): Int {
            val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return try {
                val intValue = prefs.getInt(KEY_TAP_COUNT, -1)
                if (intValue >= 0) intValue else (prefs.getString(KEY_TAP_COUNT, "0")?.toIntOrNull() ?: 0)
            } catch (e: Exception) {
                try {
                    prefs.getString(KEY_TAP_COUNT, "0")?.toIntOrNull() ?: 0
                } catch (e2: Exception) {
                    0
                }
            }
        }
    }
}

