import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AccessibilityHelper {
  static const MethodChannel _channel = MethodChannel('accessibility_helper');

  /// فتح إعدادات Accessibility
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      // إذا فشل، نفتح إعدادات النظام العامة
      await openAppSettings();
    }
  }

  /// التحقق من تفعيل Accessibility Service
  static Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// الحصول على package name التطبيق النشط الحالي
  static Future<String?> getCurrentAppPackage() async {
    try {
      final result = await _channel.invokeMethod<String>('getCurrentAppPackage');
      return result;
    } catch (e) {
      return null;
    }
  }
}

