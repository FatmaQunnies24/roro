import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../service/assessment_service.dart';
import '../model/assessment_model.dart';
import '../utils/stress_calculator.dart';
import '../utils/background_service.dart';
import '../utils/accessibility_helper.dart';
import 'assessment_details_view.dart';

class MonitoringView extends StatefulWidget {
  final String userId;
  final String playMode;

  const MonitoringView({
    super.key,
    required this.userId,
    this.playMode = 'فردي',
  });

  @override
  State<MonitoringView> createState() => _MonitoringViewState();
}

class _MonitoringViewState extends State<MonitoringView> with WidgetsBindingObserver {
  bool _isMonitoring = false;
  bool _isInitializing = true; // لمنع الاستدعاء المزدوج
  bool _hasStartedMonitoring = false; // للتأكد من عدم البدء مرتين
  
  int _tapCount = 0;
  List<double> _soundLevels = [];
  int _screamCount = 0;
  int _monitoringDuration = 0;
  Timer? _monitoringTimer;
  Timer? _soundCheckTimer;
  Timer? _saveTimer;
  
  double _currentSoundLevel = 0.0;
  String? _lastTapPackage;
  String? _lastTapTime; // millis as string من خدمة إمكانية الوصول

  @override
  void initState() {
    super.initState();
    debugPrint('=== initState: بدء تهيئة MonitoringView ===');
    WidgetsBinding.instance.addObserver(this);
    
    // تحميل البيانات أولاً
    _loadSavedData();
    
    // ثم طلب الصلاحيات بعد تأخير بسيط لضمان أن الـ context جاهز
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('=== PostFrameCallback: طلب الصلاحيات ===');
      _requestPermissions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _monitoringTimer?.cancel();
    _soundCheckTimer?.cancel();
    _saveTimer?.cancel();
    _saveData(); // حفظ نهائي
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // التطبيق في الخلفية - لكن المراقبة تستمر
      _saveData(); // حفظ فوري عند الخروج
      debugPrint('التطبيق في الخلفية - المراقبة مستمرة');
      
      // عند انتقال التطبيق للخلفية لأول مرة، نطلب الإذن
      if (_isMonitoring && !_hasRequestedPermissionForOtherApp) {
        // انتظار قليل ثم التحقق من Accessibility Service
        Future.delayed(const Duration(milliseconds: 1000), () async {
          final isEnabled = await AccessibilityHelper.isAccessibilityServiceEnabled();
          if (!isEnabled && mounted) {
            _hasRequestedPermissionForOtherApp = true;
            debugPrint('التطبيق في الخلفية - طلب إذن Accessibility لعد الضغطات في التطبيقات الأخرى');
            _showAccessibilityDialog();
          }
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // التطبيق عاد للمقدمة (مثلاً من اللعبة) - تحديث فوري لعدد الضغطات من خدمة إمكانية الوصول
      _loadSavedData();
      debugPrint('التطبيق عاد للمقدمة - تم استعادة عدد الضغطات من التطبيقات الأخرى');
    }
  }

  // تحميل البيانات المحفوظة
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final savedTapCount = prefs.getInt('monitoring_tapCount') ?? 0;
      // قراءة العدد مباشرة من نفس الملف الذي تكتب فيه خدمة إمكانية الوصول (ضمان ظهور العدد بعد الضغط في واتساب وغيره)
      final nativeTapCount = await AccessibilityHelper.getTapCountFromNative();
      final tapCountToUse = savedTapCount > nativeTapCount ? savedTapCount : nativeTapCount;
      final savedDuration = prefs.getInt('monitoring_duration') ?? 0;
      final savedScreamCount = prefs.getInt('monitoring_screamCount') ?? 0;
      final savedSoundLevels = prefs.getString('monitoring_soundLevels');
      final wasActive = prefs.getBool('monitoring_isActive') ?? false;
      final lastTapPkg = prefs.getString('last_tap_package');
      final lastTapTs = prefs.getString('last_tap_time');
      
      if (mounted) {
        setState(() {
          _lastTapPackage = lastTapPkg;
          _lastTapTime = lastTapTs;
          if (tapCountToUse > _tapCount) {
            _tapCount = tapCountToUse;
          }
          if (savedDuration > _monitoringDuration) {
            _monitoringDuration = savedDuration;
          }
          if (savedScreamCount > _screamCount) {
            _screamCount = savedScreamCount;
          }
          if (savedSoundLevels != null && savedSoundLevels.isNotEmpty) {
            final newLevels = savedSoundLevels.split(',').map((e) => double.tryParse(e) ?? 0.0).toList();
            if (newLevels.length > _soundLevels.length) {
              _soundLevels = newLevels;
            }
          }
          // إذا كانت المراقبة نشطة، نستمر (لكن فقط بعد انتهاء التهيئة)
          if (wasActive && !_isMonitoring && !_isInitializing && !_hasStartedMonitoring) {
            // سنبدأ المراقبة بعد انتهاء التهيئة
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_hasStartedMonitoring) {
                _startMonitoring();
              }
            });
          }
        });
      }
      debugPrint('تم تحميل البيانات: taps=$tapCountToUse (native=$nativeTapCount) duration=$savedDuration screams=$savedScreamCount');
    } catch (e) {
      debugPrint('خطأ في تحميل البيانات: $e');
    }
  }

  // حفظ البيانات (لا نستبدل عدد الضغطات بقيمة أقل — نقرأ من Kotlin مباشرة)
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final fromPrefs = prefs.getInt('monitoring_tapCount') ?? 0;
      final fromNative = await AccessibilityHelper.getTapCountFromNative();
      final tapToSave = _tapCount > fromPrefs && _tapCount > fromNative
          ? _tapCount
          : (fromNative > fromPrefs ? fromNative : fromPrefs);
      if (tapToSave > _tapCount && mounted) {
        setState(() => _tapCount = tapToSave);
      }
      await prefs.setInt('monitoring_tapCount', tapToSave);
      await prefs.setInt('monitoring_duration', _monitoringDuration);
      await prefs.setInt('monitoring_screamCount', _screamCount);
      await prefs.setString('monitoring_soundLevels', _soundLevels.map((e) => e.toString()).join(','));
      await prefs.setBool('monitoring_isActive', _isMonitoring);
      debugPrint('تم حفظ البيانات: taps=$_tapCount, duration=$_monitoringDuration, screams=$_screamCount');
    } catch (e) {
      debugPrint('خطأ في حفظ البيانات: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      debugPrint('بدء طلب الصلاحيات...');
      
      // طلب إذن الميكروفون (للمستقبل عند إضافة قراءة فعلية للصوت)
      try {
        final microphoneStatus = await Permission.microphone.status;
        debugPrint('حالة إذن الميكروفون: $microphoneStatus');
        
        if (microphoneStatus.isDenied) {
          final result = await Permission.microphone.request();
          debugPrint('نتيجة طلب إذن الميكروفون: $result');
        } else if (microphoneStatus.isPermanentlyDenied) {
          debugPrint('إذن الميكروفون مرفوض بشكل دائم');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('يرجى تفعيل إذن الميكروفون من إعدادات التطبيق'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('خطأ في طلب إذن الميكروفون: $e');
      }
      
      // لا نطلب إذن Accessibility Service تلقائياً عند فتح الشاشة
      // سيتم التحقق منه فقط عند اكتشاف ضغطة في تطبيق آخر
      debugPrint('تخطي طلب إذن Accessibility Service - سيتم طلبه عند اكتشاف ضغطة في تطبيق آخر');
      
      // تهيئة الخدمة الخلفية - معطلة مؤقتاً لتجنب مشكلة الإشعار
      // await _initializeBackgroundService();
      
      // انتظار قليل
      await Future.delayed(const Duration(milliseconds: 500));
      
      // إنهاء مرحلة التهيئة
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        
        // بدء المراقبة حتى بدون إذن (سنستخدم محاكاة)
        if (!_hasStartedMonitoring) {
          debugPrint('بدء المراقبة...');
          _startMonitoring();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('خطأ في طلب الأذونات: $e');
      debugPrint('Stack trace: $stackTrace');
      // لا نوقف التطبيق، فقط نطبع الخطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تحذير: حدث خطأ في تهيئة المراقبة: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  bool _hasRequestedPermissionForOtherApp = false;

  void _checkAccessibilityPeriodically() {
    // التحقق من حالة Accessibility Service بشكل دوري
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isMonitoring || !mounted) {
        timer.cancel();
        return;
      }
      
      _checkAndRequestAccessibilityIfNeeded();
    });
  }

  Future<void> _checkAndRequestAccessibilityIfNeeded() async {
    try {
      // التحقق من flag الذي يحدده TapMonitoringService
      final prefs = await SharedPreferences.getInstance();
      final shouldRequest = prefs.getBool('should_request_accessibility') ?? false;
      
      if (shouldRequest) {
        // إزالة الـ flag
        await prefs.setBool('should_request_accessibility', false);
        
        // التحقق من حالة Accessibility Service
        final isEnabled = await AccessibilityHelper.isAccessibilityServiceEnabled();
        
        if (!isEnabled && mounted) {
          // عرض نافذة طلب الإذن
          debugPrint('تم اكتشاف ضغطة في تطبيق آخر - طلب إذن Accessibility');
          _showAccessibilityDialog();
        }
      }
    } catch (e) {
      debugPrint('خطأ في التحقق من Accessibility: $e');
    }
  }

  void _showAccessibilityDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تفعيل خدمة المراقبة'),
        content: const SingleChildScrollView(
          child: Text(
            'تم اكتشاف ضغطة في تطبيق آخر!\n\n'
            'لعد الضغطات في التطبيقات الأخرى، نحتاج إلى تفعيل خدمة إمكانية الوصول.\n\n'
            'الخطوات:\n'
            '1. اضغط على زر "فتح الإعدادات" أدناه\n'
            '2. ابحث عن "football_app" في قائمة "التطبيقات المثبتة"\n'
            '3. اضغط على "football_app"\n'
            '4. فعّل Toggle switch لخدمة Accessibility\n'
            '5. اضغط "موافق" عند ظهور نافذة التحذير\n\n'
            'بعد التفعيل، ارجع للتطبيق وسيتم تفعيل المراقبة تلقائياً.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('لاحقاً'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AccessibilityHelper.openAccessibilitySettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeBackgroundService() async {
    try {
      final service = FlutterBackgroundService();
      
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: false, // نبدأ كـ background ثم نحولها لاحقاً
          notificationChannelId: 'monitoring_channel',
          initialNotificationTitle: 'مراقبة تلقائية',
          initialNotificationContent: 'جاري المراقبة...',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );
    } catch (e) {
      debugPrint('خطأ في تهيئة الخدمة الخلفية: $e');
      // لا نوقف التطبيق، فقط نطبع الخطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تحذير: فشل تهيئة الخدمة الخلفية: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _startMonitoring() async {
    // منع الاستدعاء المزدوج
    if (_hasStartedMonitoring || _isMonitoring) {
      debugPrint('المراقبة جارية بالفعل أو تم البدء مسبقاً');
      return;
    }
    
    try {
      _hasStartedMonitoring = true;
      
      if (!mounted) return;
      
      setState(() {
        _isMonitoring = true;
        _soundLevels = [];
      });

      // حفظ حالة المراقبة
      _saveData();

      // بدء الخدمة الخلفية - مؤقتاً معطل لتجنب مشكلة الإشعار
      // TODO: إعادة تفعيل الخدمة الخلفية بعد إصلاح مشكلة الإشعار
      /*
      try {
        final service = FlutterBackgroundService();
        
        // التحقق من أن الخدمة متاحة قبل الاستدعاء
        final isRunning = await service.isRunning();
        if (isRunning) {
          // انتظار قليل قبل استدعاء الأوامر
          await Future.delayed(const Duration(milliseconds: 500));
          
          // بدء المراقبة أولاً
          try {
            service.invoke('startMonitoring');
          } catch (e) {
            debugPrint('خطأ في startMonitoring: $e');
          }
          
          // انتظار قليل لضمان إعداد الإشعار
          await Future.delayed(const Duration(milliseconds: 300));
          
          // ثم تحويل الخدمة إلى foreground
          try {
            service.invoke('setAsForeground');
          } catch (e) {
            debugPrint('خطأ في setAsForeground: $e');
          }
        } else {
          debugPrint('الخدمة الخلفية غير متاحة');
        }
      } catch (e) {
        debugPrint('خطأ في بدء الخدمة الخلفية: $e');
        // نستمر في المراقبة حتى لو فشلت الخدمة الخلفية
      }
      */
      debugPrint('الخدمة الخلفية معطلة مؤقتاً لتجنب مشكلة الإشعار');

    // مؤقت: تحديث مدة المراقبة وقراءة عدد الضغطات مباشرة من Kotlin (ضمان ظهور العدد بعد الضغط في واتساب)
    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isMonitoring) {
        _monitoringDuration++;
        AccessibilityHelper.getTapCountFromNative().then((nativeCount) {
          if (mounted && nativeCount > _tapCount) {
            setState(() => _tapCount = nativeCount);
          }
        });
        _loadSavedData().then((_) {
          _saveData();
          if (mounted) setState(() {});
        });
      }
    });

    // مؤقت للتحقق من مستوى الصوت (محاكاة) - يعمل حتى في الخلفية
    _soundCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isMonitoring) {
        _checkSoundLevel(); // يعمل حتى في الخلفية
      }
    });

    // مؤقت: تحميل أولاً من خدمة إمكانية الوصول ثم حفظ — حتى لا نستبدل العدد الذي كتبته الخدمة
    _saveTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isMonitoring) {
        _loadSavedData().then((_) {
          _saveData();
        });
        AccessibilityHelper.isAccessibilityServiceEnabled().then((isEnabled) {
          if (isEnabled && mounted) {
            setState(() {});
          }
        });
      }
    });

    // التحقق من حالة Accessibility Service بشكل دوري عند بدء المراقبة
    _checkAccessibilityPeriodically();
    } catch (e, stackTrace) {
      debugPrint('خطأ في بدء المراقبة: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // إعادة تعيين الـ flags في حالة الخطأ
      _hasStartedMonitoring = false;
      
      // في حالة الخطأ، نعيد الحالة إلى الوضع الطبيعي
      if (mounted) {
        setState(() {
          _isMonitoring = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في بدء المراقبة: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _checkSoundLevel() {
    try {
      // محاكاة قراءة مستوى الصوت
      // في الإنتاج، يمكن استخدام مكتبة لقراءة مستوى الصوت الفعلي من الميكروفون
      final random = Random();
      // محاكاة مستويات صوت واقعية
      double soundLevel;
      bool isScream = false;
      
      // زيادة احتمالية الصرخات عند زيادة الضغطات (مؤشر على التوتر)
      double screamProbability = 0.05; // 5% أساسي
      if (_tapCount > 100) {
        screamProbability = 0.15; // 15% عند كثرة الضغطات
      }
      if (_tapCount > 300) {
        screamProbability = 0.25; // 25% عند كثرة الضغطات جداً
      }
      
      // فقط إذا كانت هناك صرخة فعلية
      if (random.nextDouble() < screamProbability) {
        // صرخة - مستوى صوت عالي جداً
        soundLevel = 75 + random.nextDouble() * 25; // 75-100
        isScream = true;
      } else {
        // صوت طبيعي - مستوى منخفض
        soundLevel = 10 + random.nextDouble() * 40; // 10-50
      }
      
      // تحديث البيانات حتى لو كان التطبيق في الخلفية
      _currentSoundLevel = soundLevel;
      _soundLevels.add(soundLevel);
      
      // فقط عند الصراخ الفعلي (soundLevel > 75) نزيد العدد
      if (isScream && soundLevel > 75) {
        _screamCount++;
        _saveData(); // حفظ فوري عند اكتشاف صرخة
      }
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('خطأ في قراءة مستوى الصوت: $e');
    }
  }

  void _handleTap() async {
    if (_isMonitoring) {
      setState(() {
        _tapCount++;
      });
      // حفظ فوري عند كل ضغطة
      _saveData();
      
      // إرسال للخدمة الخلفية
      try {
        final service = FlutterBackgroundService();
        final isRunning = await service.isRunning();
        if (isRunning) {
          service.invoke('incrementTap');
        }
      } catch (e) {
        debugPrint('خطأ في إرسال incrementTap: $e');
        // نستمر حتى لو فشل الإرسال
      }
    }
  }

  Future<void> _stopMonitoring() async {
    _hasStartedMonitoring = false; // إعادة تعيين الـ flag
    
    setState(() {
      _isMonitoring = false;
    });

    _monitoringTimer?.cancel();
    _soundCheckTimer?.cancel();
    _saveTimer?.cancel();
    
    // إيقاف الخدمة الخلفية
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (isRunning) {
        try {
          service.invoke('stopMonitoring');
        } catch (e) {
          debugPrint('خطأ في stopMonitoring: $e');
        }
        try {
          service.invoke('setAsBackground');
        } catch (e) {
          debugPrint('خطأ في setAsBackground: $e');
        }
      }
    } catch (e) {
      debugPrint('خطأ في إيقاف الخدمة الخلفية: $e');
    }
    
    // تحميل البيانات النهائية من الخدمة الخلفية
    await _loadSavedData();
    
    // حفظ نهائي قبل المتابعة
    await _saveData();

    // حساب متوسط مستوى الصوت
    final averageSound = _soundLevels.isEmpty
        ? 0.0
        : _soundLevels.reduce((a, b) => a + b) / _soundLevels.length;

    // حساب عدد ساعات اللعب من مدة المراقبة
    final playHours = _monitoringDuration / 3600.0;

    // تحديد وقت اللعب (ليل/نهار) من الساعة الحالية
    final currentHour = DateTime.now().hour;
    final playTime = (currentHour >= 18 || currentHour < 6) ? 'ليل' : 'نهار';

    // إنشاء تقييم مؤقت
    final tempAssessment = AssessmentModel(
      id: '',
      userId: widget.userId,
      timestamp: DateTime.now(),
      playHoursPerDay: playHours,
      gameType: 'تنافسية', // افتراضي
      playTime: playTime,
      playMode: widget.playMode, // من الإعدادات
      stressLevel: 5.0, // افتراضي
      tapCount: _tapCount,
      averageSoundLevel: averageSound,
      screamCount: _screamCount,
      monitoringDurationSeconds: _monitoringDuration,
      predictedStressLevel: '',
      stressScore: 0.0,
    );

    // حساب مستوى التوتر
    final result = StressCalculator.calculateStress(tempAssessment);

    // إنشاء التقييم النهائي
    final assessment = AssessmentModel(
      id: '',
      userId: widget.userId,
      timestamp: DateTime.now(),
      playHoursPerDay: playHours,
      gameType: tempAssessment.gameType,
      playTime: playTime, // تم تعريفه أعلاه
      playMode: widget.playMode,
      stressLevel: tempAssessment.stressLevel,
      tapCount: _tapCount,
      averageSoundLevel: averageSound,
      screamCount: _screamCount,
      monitoringDurationSeconds: _monitoringDuration,
      predictedStressLevel: result['predictedStressLevel'] as String,
      stressScore: result['stressScore'] as double,
    );

    // حفظ التقييم
    final assessmentService = AssessmentService();
    final assessmentId = await assessmentService.addAssessment(assessment);

    // تحديث التقييم بالمعرف
    final savedAssessment = AssessmentModel(
      id: assessmentId,
      userId: assessment.userId,
      timestamp: assessment.timestamp,
      playHoursPerDay: assessment.playHoursPerDay,
      gameType: assessment.gameType,
      playTime: assessment.playTime,
      playMode: assessment.playMode,
      stressLevel: assessment.stressLevel,
      tapCount: assessment.tapCount,
      averageSoundLevel: assessment.averageSoundLevel,
      screamCount: assessment.screamCount,
      monitoringDurationSeconds: assessment.monitoringDurationSeconds,
      predictedStressLevel: assessment.predictedStressLevel,
      stressScore: assessment.stressScore,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AssessmentDetailsView(assessment: savedAssessment),
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// تنسيق رسالة "آخر ضغطات من [package] منذ X"
  String _formatLastTapFrom(String packageName, String? timeMillisStr) {
    final name = packageName.length > 25 ? '${packageName.substring(0, 22)}...' : packageName;
    if (timeMillisStr == null || timeMillisStr.isEmpty) {
      return 'آخر ضغطات من تطبيق آخر: $name';
    }
    final millis = int.tryParse(timeMillisStr) ?? 0;
    if (millis == 0) return 'آخر ضغطات من تطبيق آخر: $name';
    final diff = DateTime.now().millisecondsSinceEpoch - millis;
    final secs = diff ~/ 1000;
    final mins = secs ~/ 60;
    String ago;
    if (secs < 60) {
      ago = 'منذ $secs ثانية';
    } else if (mins < 60) {
      ago = 'منذ $mins دقيقة';
    } else {
      final hours = mins ~/ 60;
      ago = 'منذ $hours ساعة';
    }
    return 'آخر ضغطات من تطبيق آخر: $name ($ago)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراقبة تلقائية'),
        backgroundColor: Colors.blue[700],
        automaticallyImplyLeading: false,
      ),
      body: GestureDetector(
        onTap: _handleTap,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // مؤشر المراقبة
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isMonitoring ? Colors.green.withValues(alpha: 0.1) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isMonitoring ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isMonitoring ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      size: 60,
                      color: _isMonitoring ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isMonitoring ? 'جاري المراقبة...' : 'في انتظار الإذن',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isMonitoring ? Colors.green[700] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // إحصائيات المراقبة
              if (_isMonitoring) ...[
                // رسالة توضيحية
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FutureBuilder<bool>(
                              future: AccessibilityHelper.isAccessibilityServiceEnabled(),
                              builder: (context, snapshot) {
                                final isEnabled = snapshot.data ?? false;
                                return Text(
                                  isEnabled 
                                    ? '✓ خدمة إمكانية الوصول مفعّلة - عند الخروج من التطبيق والدخول لأي لعبة، تُحسب الضغطات فيها تلقائياً'
                                    : 'ملاحظة: الضغطات تُحسب فقط داخل التطبيق',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isEnabled ? Colors.green[900] : Colors.orange[900],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'يُحسب العدد في كل التطبيقات والألعاب قدر الإمكان. في التطبيقات بأزرار عادية العد دقيق؛ في الألعاب والواجهات المخصصة العدد تقديري (قد يشمل حركة المحتوى أيضاً).',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[800],
                        ),
                      ),
                      if (_lastTapPackage != null && _lastTapPackage!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _formatLastTapFrom(_lastTapPackage!, _lastTapTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        FutureBuilder<bool>(
                          future: AccessibilityHelper.isAccessibilityServiceEnabled(),
                          builder: (context, snapshot) {
                            final isEnabled = snapshot.data ?? false;
                            if (!isEnabled) {
                              return Text(
                                'للضغطات في التطبيقات الأخرى: فعّل خدمة إمكانية الوصول من الإعدادات',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange[800],
                                ),
                              );
                            }
                            return Text(
                              'لم يُستقبل أي ضغطات من تطبيقات أخرى بعد — جرّب تطبيقاً أو لعبة بأزرار عادية (مثلاً ألعاب ألغاز، تطبيقات تواصل، أو أي تطبيق فيه قوائم وأزرار واضحة).',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[800],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatCard('مدة المراقبة', _formatDuration(_monitoringDuration), Icons.timer),
                const SizedBox(height: 16),
                _buildStatCard('عدد الضغطات', _tapCount.toString(), Icons.touch_app),
                const SizedBox(height: 16),
                _buildStatCard('مستوى الصوت الحالي', '${_currentSoundLevel.toStringAsFixed(1)}%', Icons.volume_up),
                const SizedBox(height: 16),
                _buildStatCard('عدد الصرخات', _screamCount.toString(), Icons.warning),
              ],

              const SizedBox(height: 32),

              // زر إيقاف المراقبة
              if (_isMonitoring)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _stopMonitoring,
                      icon: const Icon(Icons.stop),
                      label: const Text('إيقاف المراقبة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

