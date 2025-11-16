import 'package:flutter/material.dart';
import '../model/player_model.dart';

class PlayerMetricsDetailsView extends StatelessWidget {
  final PlayerModel player;

  const PlayerMetricsDetailsView({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تفاصيل المواصفات"),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
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

            // تفاصيل المواصفات
            _buildMetricCard(
              "السرعة",
              "${player.speed.toStringAsFixed(2)} كم/ساعة",
              player.speed / 30.0,
              "السرعة تقاس بالكيلومتر في الساعة بناءً على المسافة والوقت",
              Icons.speed,
              Colors.blue,
            ),
            _buildMetricCard(
              "قوة الضربة",
              "${player.shotPower.toStringAsFixed(0)} نيوتن",
              player.shotPower / 5000.0,
              "قوة الضربة تقاس بالنيوتن بناءً على كتلة الكرة وسرعتها",
              Icons.sports_soccer,
              Colors.orange,
            ),
            _buildMetricCard(
              "قدرة التحمل",
              "${player.stamina.toStringAsFixed(1)}%",
              player.stamina / 100.0,
              "قدرة التحمل تقاس بناءً على المسافة والوقت ومعدل ضربات القلب",
              Icons.favorite,
              Colors.red,
            ),
            _buildMetricCard(
              "قوة الجسم",
              "${player.bodyStrength.toStringAsFixed(1)} كجم",
              player.bodyStrength / 200.0,
              "قوة الجسم تقاس بناءً على وزن الجسم وعدد التمارين (ضغط، قرفصاء، سحب)",
              Icons.fitness_center,
              Colors.purple,
            ),
            _buildMetricCard(
              "الاتزان",
              "${player.balance.toStringAsFixed(1)}%",
              player.balance / 100.0,
              "الاتزان تقاس بناءً على وقت الوقوف على قدم واحدة وعدد مرات فقدان الاتزان",
              Icons.balance,
              Colors.teal,
            ),
            _buildMetricCard(
              "معدل الجهد",
              "${player.effortIndex.toStringAsFixed(1)}%",
              player.effortIndex / 100.0,
              "معدل الجهد يقاس بناءً على ساعات التدريب الأسبوعية ونسبة إتمام التمارين",
              Icons.trending_up,
              Colors.indigo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    double progress,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
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

