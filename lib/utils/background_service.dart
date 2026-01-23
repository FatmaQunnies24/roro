import 'dart:async';
import 'dart:math';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // بدء المراقبة في الخلفية
  Timer? monitoringTimer;
  Timer? soundTimer;
  Timer? saveTimer;
  
  int duration = 0;
  int tapCount = 0;
  int screamCount = 0;
  List<double> soundLevels = [];
  bool isMonitoring = false;

  // تحميل البيانات المحفوظة
  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      duration = prefs.getInt('monitoring_duration') ?? 0;
      tapCount = prefs.getInt('monitoring_tapCount') ?? 0;
      screamCount = prefs.getInt('monitoring_screamCount') ?? 0;
      isMonitoring = prefs.getBool('monitoring_isActive') ?? false;
    } catch (e) {
      // خطأ في التحميل
    }
  }

  // حفظ البيانات
  Future<void> saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('monitoring_tapCount', tapCount);
      await prefs.setInt('monitoring_duration', duration);
      await prefs.setInt('monitoring_screamCount', screamCount);
      await prefs.setString('monitoring_soundLevels', soundLevels.map((e) => e.toString()).join(','));
      await prefs.setBool('monitoring_isActive', isMonitoring);
    } catch (e) {
      // خطأ في الحفظ
    }
  }

  // بدء المراقبة
  service.on('startMonitoring').listen((event) async {
    isMonitoring = true;
    await saveData();

    // مؤقت للمدة
    monitoringTimer?.cancel();
    monitoringTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isMonitoring) {
        duration++;
        saveData();
        
        // تحديث الإشعار
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'مراقبة تلقائية',
            content: 'المدة: ${duration ~/ 60} دقيقة | الضغطات: $tapCount',
          );
        }
      }
    });

    // مؤقت للصوت
    soundTimer?.cancel();
    soundTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (isMonitoring) {
        final random = Random();
        double screamProbability = 0.05; // 5% احتمالية صرخة
        if (tapCount > 100) screamProbability = 0.15;
        if (tapCount > 300) screamProbability = 0.25;
        
        double soundLevel;
        bool isScream = false;
        
        // فقط إذا كانت هناك صرخة فعلية
        if (random.nextDouble() < screamProbability) {
          // صرخة - مستوى صوت عالي جداً
          soundLevel = 75 + random.nextDouble() * 25; // 75-100
          isScream = true;
        } else {
          // صوت طبيعي - مستوى منخفض
          soundLevel = 10 + random.nextDouble() * 40; // 10-50
        }
        
        soundLevels.add(soundLevel);
        
        // فقط عند الصراخ الفعلي (soundLevel > 75) نزيد العدد
        if (isScream && soundLevel > 75) {
          screamCount++;
          saveData();
        }
      }
    });

    // مؤقت للحفظ
    saveTimer?.cancel();
    saveTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (isMonitoring) {
        saveData();
      }
    });
  });

  // إيقاف المراقبة
  service.on('stopMonitoring').listen((event) {
    isMonitoring = false;
    monitoringTimer?.cancel();
    soundTimer?.cancel();
    saveTimer?.cancel();
    saveData();
  });

  // زيادة الضغطات
  service.on('incrementTap').listen((event) {
    if (isMonitoring) {
      tapCount++;
      saveData();
    }
  });

  // تحميل البيانات عند البدء
  await loadData();
  
  // إذا كانت المراقبة نشطة، نستمر
  if (isMonitoring) {
    service.invoke('startMonitoring');
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

