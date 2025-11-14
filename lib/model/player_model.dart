import '../utils/player_metrics_calculator.dart';

class PlayerModel {
  final String id;
  final String name;
  final String teamId;
  final String positionType;
  final String roleInTeam;
  final double speed;
  final double shotPower;
  final double stamina;
  final double bodyStrength;
  final double balance;
  final double effortIndex;
  final double overallScore;
  final String statusText;

  PlayerModel({
    required this.id,
    required this.name,
    required this.teamId,
    required this.positionType,
    required this.roleInTeam,
    required this.speed,
    required this.shotPower,
    required this.stamina,
    required this.bodyStrength,
    required this.balance,
    required this.effortIndex,
    double? overallScore,
    String? statusText,
  })  : overallScore = overallScore ??
            PlayerMetricsCalculator.calculateOverallScore(
              speed: speed,
              shotPower: shotPower,
              stamina: stamina,
              bodyStrength: bodyStrength,
              balance: balance,
              effortIndex: effortIndex,
            ),
        statusText = statusText ??
            PlayerMetricsCalculator.getPerformanceDescription(
              overallScore ??
                  PlayerMetricsCalculator.calculateOverallScore(
                    speed: speed,
                    shotPower: shotPower,
                    stamina: stamina,
                    bodyStrength: bodyStrength,
                    balance: balance,
                    effortIndex: effortIndex,
                  ),
            );

  factory PlayerModel.fromMap(String id, Map<String, dynamic> data) {
    return PlayerModel(
      id: id,
      name: data['name'] ?? '',
      teamId: data['teamId'] ?? '',
      positionType: data['positionType'] ?? '',
      roleInTeam: data['roleInTeam'] ?? '',
      speed: (data['speed'] ?? 0).toDouble(),
      shotPower: (data['shotPower'] ?? 0).toDouble(),
      stamina: (data['stamina'] ?? 0).toDouble(),
      bodyStrength: (data['bodyStrength'] ?? 0).toDouble(),
      balance: (data['balance'] ?? 0).toDouble(),
      effortIndex: (data['effortIndex'] ?? 0).toDouble(),
      overallScore: (data['overallScore'] ?? 0).toDouble(),
      statusText: data['statusText'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'teamId': teamId,
      'positionType': positionType,
      'roleInTeam': roleInTeam,
      'speed': speed,
      'shotPower': shotPower,
      'stamina': stamina,
      'bodyStrength': bodyStrength,
      'balance': balance,
      'effortIndex': effortIndex,
      'overallScore': overallScore,
      'statusText': statusText,
    };
  }
}
