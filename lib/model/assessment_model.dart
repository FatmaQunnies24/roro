import 'package:cloud_firestore/cloud_firestore.dart';

class AssessmentModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  
  // المدخلات
  final double playHoursPerDay; // عدد ساعات اللعب يوميًا
  final String gameType; // تنافسية / هادئة
  final String playTime; // ليل / نهار
  final String playMode; // فردي / جماعي
  final double stressLevel; // مؤشر ذاتي للضغط (0-10)
  
  // بيانات المراقبة التلقائية
  final int tapCount; // عدد الضغطات على الشاشة
  final double averageSoundLevel; // متوسط مستوى الصوت (0-100)
  final int screamCount; // عدد الصرخات المكتشفة
  final int monitoringDurationSeconds; // مدة المراقبة بالثواني
  final int badWordsCount; // عدد مرات الكلمات السيئة
  final String badWordsReport; // تقرير الكلمات السيئة التي قيلت (للريبورت)
  
  // المخرجات
  final String predictedStressLevel; // منخفض / متوسط / مرتفع
  final double stressScore; // قيمة رقمية (0-100)
  final String reasons; // أسباب محتملة (من StressCalculator)
  final String tips; // نصائح (من StressCalculator)
  
  AssessmentModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.playHoursPerDay,
    required this.gameType,
    required this.playTime,
    required this.playMode,
    required this.stressLevel,
    this.tapCount = 0,
    this.averageSoundLevel = 0.0,
    this.screamCount = 0,
    this.monitoringDurationSeconds = 0,
    this.badWordsCount = 0,
    this.badWordsReport = '',
    required this.predictedStressLevel,
    required this.stressScore,
    this.reasons = '',
    this.tips = '',
  });

  factory AssessmentModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime timestamp = DateTime.now();
    final t = data['timestamp'];
    if (t != null && t is Timestamp) timestamp = t.toDate();

    return AssessmentModel(
      id: id,
      userId: _str(data['userId']),
      timestamp: timestamp,
      playHoursPerDay: _double(data['playHoursPerDay']),
      gameType: _str(data['gameType']),
      playTime: _str(data['playTime']),
      playMode: _str(data['playMode']),
      stressLevel: _double(data['stressLevel']),
      tapCount: _int(data['tapCount']),
      averageSoundLevel: _double(data['averageSoundLevel']),
      screamCount: _int(data['screamCount']),
      monitoringDurationSeconds: _int(data['monitoringDurationSeconds']),
      badWordsCount: _int(data['badWordsCount']),
      badWordsReport: _str(data['badWordsReport']),
      predictedStressLevel: _str(data['predictedStressLevel']),
      stressScore: _double(data['stressScore']),
      reasons: _str(data['reasons']),
      tips: _str(data['tips']),
    );
  }

  static String _str(dynamic v) {
    if (v == null) return '';
    return v.toString();
  }

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _double(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'playHoursPerDay': playHoursPerDay,
      'gameType': gameType,
      'playTime': playTime,
      'playMode': playMode,
      'stressLevel': stressLevel,
      'tapCount': tapCount,
      'averageSoundLevel': averageSoundLevel,
      'screamCount': screamCount,
      'monitoringDurationSeconds': monitoringDurationSeconds,
      'badWordsCount': badWordsCount,
      'badWordsReport': badWordsReport,
      'predictedStressLevel': predictedStressLevel,
      'stressScore': stressScore,
      'reasons': reasons,
      'tips': tips,
    };
  }
}

