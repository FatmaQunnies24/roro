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
  bool _isInitializing = true;
  bool _hasStartedMonitoring = false;
  
  int _tapCount = 0;
  int _lastKnownTapCount = 0;
  int _timeResetCounter = 0;
  List<double> _soundLevels = [];
  int _screamCount = 0;
  int _monitoringDuration = 0;
  Timer? _monitoringTimer;
  Timer? _soundCheckTimer;
  Timer? _saveTimer;
  Timer? _timeResetCheckTimer;
  
  double _currentSoundLevel = 0.0;
  String? _lastTapPackage;
  String? _lastTapTime;
  int _previousTimestamp = 0;
  int _lastNativeTapCount = 0; // لتتبع آخر قيمة من Kotlin
  bool _hasTimeResetOccurred = false; // للكشف عن حدوث تصفير وقت

  @override
  void initState() {
    super.initState();
    debugPrint('=== initState: بدء تهيئة MonitoringView ===');
    WidgetsBinding.instance.addObserver(this);
    
    _loadSavedData();
    
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
    _timeResetCheckTimer?.cancel();
    _saveData();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveData();
      debugPrint('التطبيق في الخلفية - المراقبة مستمرة');
      
      if (_isMonitoring && !_hasRequestedPermissionForOtherApp) {
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
      // عندما يعود التطبيق للمقدمة، نفحص تصفير الوقت ثم نزامن عداد الضغطات من التطبيقات الأخرى (مثل واتساب)
      _checkForTimeResetAndUpdateTaps();
      _updateTapCountWithResetHandling().then((_) {
        _saveData(); // حفظ العدد المحدث بعد مزامنة ضغطات واتساب/غيره
      });
      debugPrint('التطبيق عاد للمقدمة - التحقق من تصفير الوقت وتحديث الضغطات');
    }
  }

  // دالة جديدة للتحقق من تصفير الوقت وتحديث العداد
  Future<void> _checkForTimeResetAndUpdateTaps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      
      // الحصول على آخر timestamp
      final lastTapTs = prefs.getString('last_tap_time');
      final currentTimestamp = int.tryParse(lastTapTs ?? '0') ?? 0;
      
      // إذا كان الـ timestamp الحالي أصغر من السابق، حدث تصفير وقت
      if (_previousTimestamp > 0 && currentTimestamp > 0 && currentTimestamp < _previousTimestamp) {
        debugPrint('🔄 اكتشاف تصفير الوقت عند عودة التطبيق!');
        _hasTimeResetOccurred = true;
        
        // الحصول على العدد الحالي من Kotlin
        final nativeTapCount = await AccessibilityHelper.getTapCountFromNative();
        
        // إضافة العدد الجديد إلى العدد السابق
        setState(() {
          _tapCount += nativeTapCount;
          _lastKnownTapCount = _tapCount;
          _timeResetCounter++;
        });
        
        await _saveData();
      }
      
      // تحديث الـ timestamp
      if (currentTimestamp > 0) {
        _previousTimestamp = currentTimestamp;
      }
    } catch (e) {
      debugPrint('خطأ في التحقق من تصفير الوقت عند العودة: $e');
    }
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final savedTapCount = prefs.getInt('monitoring_tapCount') ?? 0;
      final nativeTapCount = await AccessibilityHelper.getTapCountFromNative();
      
      // منطق جديد: نأخذ القيمة الأكبر، ولكن إذا كان هناك تصفير وقت نعاملها بشكل مختلف
      int tapCountToUse = savedTapCount;
      
      // إذا كانت قيمة Kotlin أكبر، نأخذها
      if (nativeTapCount > tapCountToUse) {
        tapCountToUse = nativeTapCount;
      }
      
      // إذا كانت قيمة المحفوظة أكبر، نأخذها (حالة استمرارية)
      if (savedTapCount > tapCountToUse) {
        tapCountToUse = savedTapCount;
      }
      
      final savedDuration = prefs.getInt('monitoring_duration') ?? 0;
      final savedScreamCount = prefs.getInt('monitoring_screamCount') ?? 0;
      final savedSoundLevels = prefs.getString('monitoring_soundLevels');
      final wasActive = prefs.getBool('monitoring_isActive') ?? false;
      final lastTapPkg = prefs.getString('last_tap_package');
      final lastTapTs = prefs.getString('last_tap_time');
      final savedTimeResetCounter = prefs.getInt('monitoring_timeResetCounter') ?? 0;
      final savedPreviousTimestamp = prefs.getInt('monitoring_previousTimestamp') ?? 0;
      
      if (mounted) {
        setState(() {
          _lastTapPackage = lastTapPkg;
          _lastTapTime = lastTapTs;
          _timeResetCounter = savedTimeResetCounter;
          _previousTimestamp = savedPreviousTimestamp;
          
          if (tapCountToUse > _tapCount) {
            _tapCount = tapCountToUse;
            _lastKnownTapCount = tapCountToUse;
          }
          _lastNativeTapCount = tapCountToUse; // تهيئة حتى لا يُحسب الفرق مرتين عند التحديث
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
          if (wasActive && !_isMonitoring && !_isInitializing && !_hasStartedMonitoring) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_hasStartedMonitoring) {
                _startMonitoring();
              }
            });
          }
        });
      }
      debugPrint('تم تحميل البيانات: taps=$tapCountToUse (native=$nativeTapCount) duration=$savedDuration timeResets=$savedTimeResetCounter');
    } catch (e) {
      debugPrint('خطأ في تحميل البيانات: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      
      // الحصول على القيمة الحالية من Kotlin
      final nativeTapCount = await AccessibilityHelper.getTapCountFromNative();
      
      // منطق الحفظ الجديد:
      // 1. نأخذ القيمة الأكبر بين القيمة الحالية في الذاكرة وnative
      // 2. ولكن إذا حدث تصفير وقت، نتعامل معها بشكل مختلف
      
      int tapToSave = _tapCount;
      
      // إذا كانت قيمة native أكبر من القيمة الحالية، قد تكون ضغطات جديدة
      if (nativeTapCount > tapToSave) {
        // التحقق: هل حدث تصفير وقت؟
        if (!_hasTimeResetOccurred && nativeTapCount - _lastNativeTapCount > 0) {
          // لا يوجد تصفير وقت وهناك ضغطات جديدة
          tapToSave = nativeTapCount;
        }
      }
      
      // حفظ القيمة النهائية
      await prefs.setInt('monitoring_tapCount', tapToSave);
      await prefs.setInt('monitoring_duration', _monitoringDuration);
      await prefs.setInt('monitoring_screamCount', _screamCount);
      await prefs.setString('monitoring_soundLevels', _soundLevels.map((e) => e.toString()).join(','));
      await prefs.setBool('monitoring_isActive', _isMonitoring);
      await prefs.setInt('monitoring_timeResetCounter', _timeResetCounter);
      await prefs.setInt('monitoring_previousTimestamp', _previousTimestamp);
      
      // تحديث آخر قيمة native عرفناها
      _lastNativeTapCount = nativeTapCount;
      
      debugPrint('تم حفظ البيانات: taps=$tapToSave, native=$nativeTapCount, duration=$_monitoringDuration, timeResets=$_timeResetCounter');
    } catch (e) {
      debugPrint('خطأ في حفظ البيانات: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      debugPrint('بدء طلب الصلاحيات...');
      
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
      
      debugPrint('تخطي طلب إذن Accessibility Service - سيتم طلبه عند اكتشاف ضغطة في تطبيق آخر');
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        
        if (!_hasStartedMonitoring) {
          debugPrint('بدء المراقبة...');
          _startMonitoring();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('خطأ في طلب الأذونات: $e');
      debugPrint('Stack trace: $stackTrace');
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
      final prefs = await SharedPreferences.getInstance();
      final shouldRequest = prefs.getBool('should_request_accessibility') ?? false;
      
      if (shouldRequest) {
        await prefs.setBool('should_request_accessibility', false);
        
        final isEnabled = await AccessibilityHelper.isAccessibilityServiceEnabled();
        
        if (!isEnabled && mounted) {
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
          isForegroundMode: false,
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

  // دالة محسنة للتحقق من تصفير الوقت
  void _checkTimeReset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final lastTapTs = prefs.getString('last_tap_time');
      
      if (lastTapTs != null && lastTapTs.isNotEmpty) {
        final currentTimestamp = int.tryParse(lastTapTs) ?? 0;
        
        debugPrint('🔍 فحص التصفير: previousTimestamp=$_previousTimestamp, currentTimestamp=$currentTimestamp');
        
        // إذا كان الـ timestamp الحالي أصغر من السابق، حدث تصفير وقت
        if (_previousTimestamp > 0 && currentTimestamp > 0 && currentTimestamp < _previousTimestamp) {
          debugPrint('🔄 تم اكتشاف تصفير الوقت! القديم: $_previousTimestamp، الجديد: $currentTimestamp');
          
          // تسجيل أن تصفير الوقت حدث
          _hasTimeResetOccurred = true;
          
          // الحصول على العدد الحالي من Kotlin (بعد التصفير)
          final nativeTapCount = await AccessibilityHelper.getTapCountFromNative();
          
          // زيادة العداد - نضيف العدد الجديد إلى العدد السابق
          final newTapCount = _tapCount + nativeTapCount;
          
          setState(() {
            _tapCount = newTapCount;
            _timeResetCounter++;
            _lastKnownTapCount = newTapCount;
          });
          
          // حفظ البيانات المحدثة
          await _saveData();
          
          debugPrint('✅ تم تحديث العداد بعد التصفير: $_tapCount (أضيف $nativeTapCount)');
        }
        
        // تحديث الـ timestamp
        if (currentTimestamp > 0) {
          _previousTimestamp = currentTimestamp;
          await prefs.setInt('monitoring_previousTimestamp', _previousTimestamp);
        }
      }
    } catch (e) {
      debugPrint('خطأ في التحقق من تصفير الوقت: $e');
    }
  }

  // دالة جديدة: تحديث العداد مع التعامل مع تصفير الوقت
  Future<void> _updateTapCountWithResetHandling() async {
    try {
      final nativeTapCount = await AccessibilityHelper.getTapCountFromNative();
      
      // التحقق من تصفير الوقت أولاً
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final lastTapTs = prefs.getString('last_tap_time');
      final currentTimestamp = int.tryParse(lastTapTs ?? '0') ?? 0;
      
      // إذا حدث تصفير وقت (timestamp جديد أصغر من السابق)
      if (_previousTimestamp > 0 && currentTimestamp > 0 && currentTimestamp < _previousTimestamp) {
        debugPrint('⚡ حدث تصفير وقت أثناء التحديث!');
        _hasTimeResetOccurred = true;
        
        // نضيف العدد الجديد إلى العدد الحالي
        final newTotal = _tapCount + nativeTapCount;
        
        if (mounted) {
          setState(() {
            _tapCount = newTotal;
            _lastKnownTapCount = newTotal;
            _timeResetCounter++;
          });
        }
        
        _previousTimestamp = currentTimestamp;
      } 
      // إذا لم يحدث تصفير وقت وكانت هناك ضغطات جديدة
      else if (nativeTapCount > _lastNativeTapCount) {
        final difference = nativeTapCount - _lastNativeTapCount;
        debugPrint('➕ اكتشاف $difference ضغطة جديدة من تطبيقات أخرى');
        
        if (mounted) {
          setState(() {
            _tapCount += difference;
            _lastKnownTapCount = _tapCount;
          });
        }
      }
      
      // تحديث آخر قيمة native
      _lastNativeTapCount = nativeTapCount;
      _previousTimestamp = currentTimestamp;
      
    } catch (e) {
      debugPrint('خطأ في تحديث عداد الضغطات: $e');
    }
  }

  void _startMonitoring() async {
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

      // مزامنة عداد الضغطات من native (تطبيقات أخرى) عند بدء المراقبة
      final initialNative = await AccessibilityHelper.getTapCountFromNative();
      if (initialNative > _tapCount) {
        if (mounted) setState(() {
          _tapCount = initialNative;
          _lastKnownTapCount = initialNative;
        });
      }
      _lastNativeTapCount = initialNative;

      _saveData();

      // مؤقت: تحديث مدة المراقبة
      _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isMonitoring) {
          _monitoringDuration++;
          
          // تحديث عداد الضغطات مع التعامل مع تصفير الوقت
          _updateTapCountWithResetHandling();
          
          _saveData();
          if (mounted) setState(() {});
        }
      });

      // مؤقت للتحقق من مستوى الصوت (محاكاة)
      _soundCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (_isMonitoring) {
          _checkSoundLevel();
        }
      });

      // مؤقت للتحقق من تصفير الوقت
      _timeResetCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (_isMonitoring) {
          _checkTimeReset();
        }
      });

      _checkAccessibilityPeriodically();
    } catch (e, stackTrace) {
      debugPrint('خطأ في بدء المراقبة: $e');
      debugPrint('Stack trace: $stackTrace');
      
      _hasStartedMonitoring = false;
      
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
      final random = Random();
      double soundLevel;
      bool isScream = false;
      
      double screamProbability = 0.05;
      if (_tapCount > 100) {
        screamProbability = 0.15;
      }
      if (_tapCount > 300) {
        screamProbability = 0.25;
      }
      
      if (random.nextDouble() < screamProbability) {
        soundLevel = 75 + random.nextDouble() * 25;
        isScream = true;
      } else {
        soundLevel = 10 + random.nextDouble() * 40;
      }
      
      _currentSoundLevel = soundLevel;
      _soundLevels.add(soundLevel);
      
      if (isScream && soundLevel > 75) {
        _screamCount++;
        _saveData();
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
      _saveData();
      
      try {
        final service = FlutterBackgroundService();
        final isRunning = await service.isRunning();
        if (isRunning) {
          service.invoke('incrementTap');
        }
      } catch (e) {
        debugPrint('خطأ في إرسال incrementTap: $e');
      }
    }
  }

  Future<void> _stopMonitoring() async {
    _hasStartedMonitoring = false;
    
    setState(() {
      _isMonitoring = false;
    });

    _monitoringTimer?.cancel();
    _soundCheckTimer?.cancel();
    _saveTimer?.cancel();
    _timeResetCheckTimer?.cancel();
    
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
    
    await _loadSavedData();
    await _saveData();

    final averageSound = _soundLevels.isEmpty
        ? 0.0
        : _soundLevels.reduce((a, b) => a + b) / _soundLevels.length;

    final playHours = _monitoringDuration / 3600.0;
    final currentHour = DateTime.now().hour;
    final playTime = (currentHour >= 18 || currentHour < 6) ? 'ليل' : 'نهار';

    final tempAssessment = AssessmentModel(
      id: '',
      userId: widget.userId,
      timestamp: DateTime.now(),
      playHoursPerDay: playHours,
      gameType: 'تنافسية',
      playTime: playTime,
      playMode: widget.playMode,
      stressLevel: 5.0,
      tapCount: _tapCount,
      averageSoundLevel: averageSound,
      screamCount: _screamCount,
      monitoringDurationSeconds: _monitoringDuration,
      predictedStressLevel: '',
      stressScore: 0.0,
    );

    final result = StressCalculator.calculateStress(tempAssessment);

    final assessment = AssessmentModel(
      id: '',
      userId: widget.userId,
      timestamp: DateTime.now(),
      playHoursPerDay: playHours,
      gameType: tempAssessment.gameType,
      playTime: playTime,
      playMode: widget.playMode,
      stressLevel: tempAssessment.stressLevel,
      tapCount: _tapCount,
      averageSoundLevel: averageSound,
      screamCount: _screamCount,
      monitoringDurationSeconds: _monitoringDuration,
      predictedStressLevel: result['predictedStressLevel'] as String,
      stressScore: result['stressScore'] as double,
    );

    final assessmentService = AssessmentService();
    final assessmentId = await assessmentService.addAssessment(assessment);

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
                  color: _isMonitoring ? Colors.green.withOpacity(0.1) : Colors.grey[200],
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
                              'لم يُستقبل أي ضغطات من تطبيقات أخرى بعد — جرّب تطبيقاً أو لعبة بأزرار عادية',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[800],
                              ),
                            );
                          },
                        ),
                      ],
                      // عرض حالة تصفير الوقت إذا حدث
                      if (_hasTimeResetOccurred) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.autorenew, color: Colors.blue[700], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'تم اكتشاف تصفير الوقت وإضافة الضغطات الجديدة إلى المجموع',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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

  Widget _buildStatCard(String label, String value, IconData icon, {String? subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
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
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
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