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
  
  int _tapCount = 0;
  List<double> _soundLevels = [];
  int _screamCount = 0;
  int _monitoringDuration = 0;
  Timer? _monitoringTimer;
  Timer? _soundCheckTimer;
  Timer? _saveTimer;
  
  double _currentSoundLevel = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedData();
    _requestPermissions();
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
    } else if (state == AppLifecycleState.resumed) {
      // التطبيق عاد للمقدمة - تحديث البيانات من Accessibility Service
      _loadSavedData(); // استعادة البيانات
      // تحديث دوري للبيانات من Accessibility Service
      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (!_isMonitoring || !mounted) {
          timer.cancel();
          return;
        }
        _loadSavedData();
      });
      debugPrint('التطبيق عاد للمقدمة - تم استعادة البيانات');
    }
  }

  // تحميل البيانات المحفوظة
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTapCount = prefs.getInt('monitoring_tapCount') ?? 0;
      final savedDuration = prefs.getInt('monitoring_duration') ?? 0;
      final savedScreamCount = prefs.getInt('monitoring_screamCount') ?? 0;
      final savedSoundLevels = prefs.getString('monitoring_soundLevels');
      final wasActive = prefs.getBool('monitoring_isActive') ?? false;
      
      // تحديث القيم فقط إذا كانت أكبر (لتجنب فقدان البيانات من Accessibility Service)
      if (mounted) {
        setState(() {
          // استخدام القيمة الأكبر بين المحفوظة والحالية (لضمان عدم فقدان البيانات من Accessibility Service)
          if (savedTapCount > _tapCount) {
            _tapCount = savedTapCount;
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
          // إذا كانت المراقبة نشطة، نستمر
          if (wasActive && !_isMonitoring) {
            _isMonitoring = true;
            _startMonitoring();
          }
        });
      }
      debugPrint('تم تحميل البيانات: taps=$savedTapCount, duration=$savedDuration, screams=$savedScreamCount');
    } catch (e) {
      debugPrint('خطأ في تحميل البيانات: $e');
    }
  }

  // حفظ البيانات
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('monitoring_tapCount', _tapCount);
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
    // طلب إذن الميكروفون (للمستقبل عند إضافة قراءة فعلية للصوت)
    await Permission.microphone.request();
    
    // التحقق من تفعيل Accessibility Service
    final isAccessibilityEnabled = await AccessibilityHelper.isAccessibilityServiceEnabled();
    if (!isAccessibilityEnabled && mounted) {
      _showAccessibilityDialog();
    }
    
    // تهيئة الخدمة الخلفية
    await _initializeBackgroundService();
    
    // بدء المراقبة حتى بدون إذن (سنستخدم محاكاة)
    _startMonitoring();
  }

  void _showAccessibilityDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تفعيل خدمة المراقبة'),
        content: const Text(
          'لعد الضغطات في التطبيقات الأخرى، نحتاج إلى تفعيل خدمة إمكانية الوصول.\n\n'
          'سيتم فتح إعدادات Android. ابحث عن "football_app" أو "TapMonitoringService" وفعّلها.',
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
    final service = FlutterBackgroundService();
    
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
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
  }

  void _startMonitoring() async {
    setState(() {
      _isMonitoring = true;
      _soundLevels = [];
    });

    // حفظ حالة المراقبة
    _saveData();

    // بدء الخدمة الخلفية
    final service = FlutterBackgroundService();
    service.invoke('setAsForeground');
    service.invoke('startMonitoring');

    // مؤقت لتحديث مدة المراقبة - يعمل حتى في الخلفية
    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isMonitoring) {
        // تحديث المدة حتى لو كان التطبيق في الخلفية
        _monitoringDuration++;
        _saveData(); // حفظ البيانات كل ثانية
        
        // تحديث البيانات من الخدمة الخلفية
        _loadSavedData();
        
        if (mounted) {
          setState(() {});
        }
      }
    });

    // مؤقت للتحقق من مستوى الصوت (محاكاة) - يعمل حتى في الخلفية
    _soundCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isMonitoring) {
        _checkSoundLevel(); // يعمل حتى في الخلفية
      }
    });

    // مؤقت لحفظ البيانات كل ثانيتين (لضمان عدم فقدان البيانات)
    _saveTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isMonitoring) {
        _saveData();
        // تحديث دوري من Accessibility Service (يعمل حتى في الخلفية)
        _loadSavedData();
      }
    });
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
      final service = FlutterBackgroundService();
      service.invoke('incrementTap');
    }
  }

  Future<void> _stopMonitoring() async {
    setState(() {
      _isMonitoring = false;
    });

    _monitoringTimer?.cancel();
    _soundCheckTimer?.cancel();
    _saveTimer?.cancel();
    
    // إيقاف الخدمة الخلفية
    final service = FlutterBackgroundService();
    service.invoke('stopMonitoring');
    service.invoke('setAsBackground');
    
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
                            child: Text(
                              'ملاحظة: الضغطات تُحسب فقط داخل التطبيق',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'للضغطات في التطبيقات الأخرى: فعّل خدمة إمكانية الوصول من الإعدادات',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[800],
                        ),
                      ),
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

