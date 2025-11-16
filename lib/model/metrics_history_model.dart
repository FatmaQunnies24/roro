import 'package:cloud_firestore/cloud_firestore.dart';

class MetricsHistoryModel {
  final String id;
  final String playerId;
  final DateTime timestamp;
  final double speed;
  final double shotPower;
  final double stamina;
  final double bodyStrength;
  final double balance;
  final double effortIndex;
  final double overallScore;
  final int trainingDurationSeconds; // مدة التدريب بالثواني

  MetricsHistoryModel({
    required this.id,
    required this.playerId,
    required this.timestamp,
    required this.speed,
    required this.shotPower,
    required this.stamina,
    required this.bodyStrength,
    required this.balance,
    required this.effortIndex,
    required this.overallScore,
    required this.trainingDurationSeconds,
  });

  factory MetricsHistoryModel.fromMap(String id, Map<String, dynamic> data) {
    return MetricsHistoryModel(
      id: id,
      playerId: data['playerId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      speed: (data['speed'] ?? 0).toDouble(),
      shotPower: (data['shotPower'] ?? 0).toDouble(),
      stamina: (data['stamina'] ?? 0).toDouble(),
      bodyStrength: (data['bodyStrength'] ?? 0).toDouble(),
      balance: (data['balance'] ?? 0).toDouble(),
      effortIndex: (data['effortIndex'] ?? 0).toDouble(),
      overallScore: (data['overallScore'] ?? 0).toDouble(),
      trainingDurationSeconds: data['trainingDurationSeconds'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'timestamp': Timestamp.fromDate(timestamp),
      'speed': speed,
      'shotPower': shotPower,
      'stamina': stamina,
      'bodyStrength': bodyStrength,
      'balance': balance,
      'effortIndex': effortIndex,
      'overallScore': overallScore,
      'trainingDurationSeconds': trainingDurationSeconds,
    };
  }
}

