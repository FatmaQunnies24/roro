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
  
  // المخرجات
  final String predictedStressLevel; // منخفض / متوسط / مرتفع
  final double stressScore; // قيمة رقمية (0-100)
  
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
    required this.predictedStressLevel,
    required this.stressScore,
  });

  factory AssessmentModel.fromMap(String id, Map<String, dynamic> data) {
    return AssessmentModel(
      id: id,
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      playHoursPerDay: (data['playHoursPerDay'] ?? 0.0).toDouble(),
      gameType: data['gameType'] ?? '',
      playTime: data['playTime'] ?? '',
      playMode: data['playMode'] ?? '',
      stressLevel: (data['stressLevel'] ?? 0.0).toDouble(),
      tapCount: data['tapCount'] ?? 0,
      averageSoundLevel: (data['averageSoundLevel'] ?? 0.0).toDouble(),
      screamCount: data['screamCount'] ?? 0,
      monitoringDurationSeconds: data['monitoringDurationSeconds'] ?? 0,
      predictedStressLevel: data['predictedStressLevel'] ?? '',
      stressScore: (data['stressScore'] ?? 0.0).toDouble(),
    );
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
      'predictedStressLevel': predictedStressLevel,
      'stressScore': stressScore,
    };
  }
}

