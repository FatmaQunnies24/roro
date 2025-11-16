import 'package:flutter/material.dart';
import '../service/player_service.dart';
import '../service/exercise_service.dart';
import '../model/player_model.dart';
import 'player_exercises_view.dart';

class PlayerDetailsView extends StatelessWidget {
  final String playerId;
  const PlayerDetailsView({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("معلومات اللاعب"),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<PlayerModel>(
        stream: PlayerService().getPlayerById(playerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    "حدث خطأ: ${snapshot.error}",
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("رجوع"),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "اللاعب غير موجود",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("رجوع"),
                  ),
                ],
              ),
            );
          }

          final player = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // بطاقة المعلومات الأساسية
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text("المركز: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(_getPositionArabic(player.positionType)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text("الدور في الفريق: ", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(_getRoleArabic(player.roleInTeam)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // بطاقة المواصفات
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "المواصفات",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildMetricRow("السرعة", "${player.speed.toStringAsFixed(1)} كم/س", player.speed / 30.0),
                        _buildMetricRow("قوة الضربة", "${player.shotPower.toStringAsFixed(0)} نيوتن", player.shotPower / 5000.0),
                        _buildMetricRow("قدرة التحمل", "${player.stamina.toStringAsFixed(1)}%", player.stamina / 100.0),
                        _buildMetricRow("قوة الجسم", "${player.bodyStrength.toStringAsFixed(1)} كجم", player.bodyStrength / 200.0),
                        _buildMetricRow("الاتزان", "${player.balance.toStringAsFixed(1)}%", player.balance / 100.0),
                        _buildMetricRow("معدل الجهد", "${player.effortIndex.toStringAsFixed(1)}%", player.effortIndex / 100.0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // بطاقة النتيجة الإجمالية
                Card(
                  elevation: 4,
                  color: _getScoreColor(player.overallScore),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "النتيجة الإجمالية",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${player.overallScore.toStringAsFixed(1)}%",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: player.overallScore / 100.0,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getScoreColor(player.overallScore),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // بطاقة وصف الأداء
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "تحليل الأداء",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          player.statusText,
                          style: TextStyle(
                            fontSize: 16,
                            color: _getScoreColor(player.overallScore),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // زر عرض التمارين
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerExercisesView(playerId: playerId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.fitness_center),
                    label: const Text("عرض التمارين المناسبة"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(value),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.7 ? Colors.green : progress > 0.4 ? Colors.orange : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 65) return Colors.lightGreen;
    if (score >= 50) return Colors.orange;
    if (score >= 35) return Colors.deepOrange;
    return Colors.red;
  }

  String _getPositionArabic(String position) {
    switch (position.toLowerCase()) {
      case 'forward':
        return 'هجوم';
      case 'defender':
        return 'دفاع';
      case 'midfield':
        return 'وسط';
      case 'goalkeeper':
        return 'حارس مرمى';
      case 'substitute':
        return 'احتياطي';
      default:
        return position;
    }
  }

  String _getRoleArabic(String role) {
    switch (role.toLowerCase()) {
      case 'starter':
        return 'أساسي';
      case 'reserve':
        return 'احتياطي';
      default:
        return role;
    }
  }
}
