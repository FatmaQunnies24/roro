package com.example.football_app

import android.content.Intent
import android.provider.Settings
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.view.accessibility.AccessibilityManager
import android.app.ActivityManager
import android.app.usage.UsageStatsManager
import android.os.Build
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "accessibility_helper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(true)
                }
                "isAccessibilityServiceEnabled" -> {
                    val isEnabled = isAccessibilityServiceEnabled(this)
                    result.success(isEnabled)
                }
                "getCurrentAppPackage" -> {
                    val packageName = getCurrentAppPackage()
                    result.success(packageName)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isAccessibilityServiceEnabled(context: Context): Boolean {
        val accessibilityManager = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = accessibilityManager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        
        for (service in enabledServices) {
            if (service.resolveInfo.serviceInfo.packageName == context.packageName) {
                return true
            }
        }
        return false
    }

    private fun getCurrentAppPackage(): String? {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val time = System.currentTimeMillis()
                val stats = usageStatsManager.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    time - 1000 * 60, // آخر دقيقة
                    time
                )
                
                if (stats != null && stats.isNotEmpty()) {
                    var mostRecentUsedApp: String? = null
                    var mostRecentTime: Long = 0
                    
                    for (usageStats in stats) {
                        if (usageStats.lastTimeUsed > mostRecentTime) {
                            mostRecentTime = usageStats.lastTimeUsed
                            mostRecentUsedApp = usageStats.packageName
                        }
                    }
                    
                    if (mostRecentUsedApp != null) {
                        return mostRecentUsedApp
                    }
                }
            }
            
            // طريقة بديلة للـ Android القديم
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
                val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                @Suppress("DEPRECATION")
                val tasks = activityManager.getRunningTasks(1)
                if (tasks.isNotEmpty()) {
                    return tasks[0].topActivity?.packageName
                }
            }
        } catch (e: Exception) {
            // في حالة الخطأ، نعيد package name التطبيق الحالي
        }
        return packageName
    }
}
