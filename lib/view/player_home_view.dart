import 'package:flutter/material.dart';
import '../service/player_service.dart';
import '../model/player_model.dart';
import 'player_details_view.dart';
import 'player_exercises_view.dart';

class PlayerHomeView extends StatelessWidget {
  final String playerId;
  const PlayerHomeView({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة اللاعب"),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<PlayerModel>(
        stream: PlayerService().getPlayerById(playerId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final player = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // بطاقة ترحيبية
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "مرحباً ${player.name}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "النتيجة الإجمالية: ${player.overallScore.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // زر عرض الأداء
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerDetailsView(playerId: playerId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assessment, size: 28),
                    label: const Text(
                      "عرض أدائي ومعلوماتي",
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                    icon: const Icon(Icons.fitness_center, size: 28),
                    label: const Text(
                      "عرض التمارين المناسبة",
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ملخص سريع للمواصفات
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ملخص المواصفات",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildQuickMetric("السرعة", player.speed, 30),
                        _buildQuickMetric("قوة الضربة", player.shotPower, 5000),
                        _buildQuickMetric("التحمل", player.stamina, 100),
                        _buildQuickMetric("قوة الجسم", player.bodyStrength, 200),
                        _buildQuickMetric("الاتزان", player.balance, 100),
                      ],
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

  Widget _buildQuickMetric(String label, double value, double max) {
    final percentage = ((value / max) * 100).clamp(0.0, 100.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 70 ? Colors.green : percentage > 40 ? Colors.orange : Colors.red,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              "${percentage.toStringAsFixed(0)}%",
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
