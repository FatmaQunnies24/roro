import 'package:flutter/material.dart';
import '../service/player_service.dart';
import '../service/metrics_history_service.dart';
import '../service/exercise_service.dart';
import '../model/player_model.dart';
import '../model/metrics_history_model.dart';
import 'player_exercises_view.dart';
import 'player_training_view.dart';
import 'player_metric_detail_view.dart';
import 'player_metrics_list_view.dart';

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

          return StreamBuilder<List<MetricsHistoryModel>>(
            stream: MetricsHistoryService().getAllMetrics(playerId),
            builder: (context, historySnapshot) {
              final history = historySnapshot.data ?? [];
              final metricsCount = history.length;

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
                            const SizedBox(height: 12),
                            // عدد التدريبات
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.fitness_center, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    "عدد التدريبات: $metricsCount",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // قائمة التدريبات مع التاريخ
                    if (history.isNotEmpty) ...[
                      const Text(
                        "التدريبات",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...history.map((metric) => _buildMetricCard(
                            context,
                            metric,
                            player,
                          )),
                      const SizedBox(height: 16),
                    ],

                    // آخر 7 تدريبات مع التحسن
                    if (history.length > 1) ...[
                      const Text(
                        "التحسن (آخر 7 تدريبات)",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildImprovementCard(player, history),
                      const SizedBox(height: 16),
                    ],

                    // آخر تدريب وتحليل الأداء
                    Card(
                      elevation: 4,
                      color: _getScoreColor(player.overallScore).withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "آخر تدريب",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (history.isNotEmpty) ...[
                              _buildLastMetricInfo(history.first),
                            ] else
                              const Text("لا توجد تدريبات سابقة"),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 8),
                            Text(
                              "النتيجة الإجمالية: ${player.overallScore.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(player.overallScore),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // زر عرض جميع التدريبات
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerMetricsListView(playerId: playerId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.analytics),
                        label: const Text("عرض جميع التدريبات"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // زر ابدأ التدريب
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerTrainingView(playerId: playerId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text("ابدأ التدريب"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
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
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    MetricsHistoryModel metric,
    PlayerModel player,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // عرض تفاصيل المواصفة
          _showMetricDetails(context, metric, player);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _getScoreColor(metric.overallScore),
                radius: 30,
                child: Text(
                  "${metric.overallScore.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(metric.timestamp),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "مدة التدريب: ${_formatDuration(metric.trainingDurationSeconds)}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "النتيجة: ${metric.overallScore.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 14,
                        color: _getScoreColor(metric.overallScore),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImprovementCard(PlayerModel player, List<MetricsHistoryModel> history) {
    if (history.length < 2) return const SizedBox.shrink();

    final current = history.first;
    final previous = history[1];
    
    final speedImprovement = current.speed - previous.speed;
    final shotPowerImprovement = current.shotPower - previous.shotPower;
    final staminaImprovement = current.stamina - previous.stamina;
    final bodyStrengthImprovement = current.bodyStrength - previous.bodyStrength;
    final balanceImprovement = current.balance - previous.balance;
    final effortIndexImprovement = current.effortIndex - previous.effortIndex;
    final overallImprovement = current.overallScore - previous.overallScore;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                      const Text(
                        "مقارنة مع التدريب السابق",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            const SizedBox(height: 12),
            _buildImprovementRow("السرعة", speedImprovement, "كم/ساعة"),
            _buildImprovementRow("قوة الضربة", shotPowerImprovement, "نيوتن"),
            _buildImprovementRow("قدرة التحمل", staminaImprovement, "%"),
            _buildImprovementRow("قوة الجسم", bodyStrengthImprovement, "كجم"),
            _buildImprovementRow("الاتزان", balanceImprovement, "%"),
            _buildImprovementRow("معدل الجهد", effortIndexImprovement, "%"),
            const Divider(),
            _buildImprovementRow(
              "النتيجة الإجمالية",
              overallImprovement,
              "%",
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementRow(String label, double improvement, String unit, {bool isBold = false}) {
    final isPositive = improvement > 0;
    final isNegative = improvement < 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up
                    : isNegative
                        ? Icons.trending_down
                        : Icons.trending_flat,
                color: isPositive
                    ? Colors.green
                    : isNegative
                        ? Colors.red
                        : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                "${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(2)} $unit",
                style: TextStyle(
                  fontSize: isBold ? 16 : 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: isPositive
                      ? Colors.green[700]
                      : isNegative
                          ? Colors.red[700]
                          : Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastMetricInfo(MetricsHistoryModel metric) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "التاريخ: ${_formatDate(metric.timestamp)}",
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          "مدة التدريب: ${_formatDuration(metric.trainingDurationSeconds)}",
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricInfoItem("السرعة", "${metric.speed.toStringAsFixed(2)} كم/ساعة"),
            ),
            Expanded(
              child: _buildMetricInfoItem("قوة الضربة", "${metric.shotPower.toStringAsFixed(0)} نيوتن"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricInfoItem("قدرة التحمل", "${metric.stamina.toStringAsFixed(1)}%"),
            ),
            Expanded(
              child: _buildMetricInfoItem("قوة الجسم", "${metric.bodyStrength.toStringAsFixed(1)} كجم"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricInfoItem("الاتزان", "${metric.balance.toStringAsFixed(1)}%"),
            ),
            Expanded(
              child: _buildMetricInfoItem("معدل الجهد", "${metric.effortIndex.toStringAsFixed(1)}%"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricInfoItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showMetricDetails(BuildContext context, MetricsHistoryModel metric, PlayerModel player) {
    // عرض تفاصيل التدريب - يمكن استخدام صفحة منفصلة أو dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                "تفاصيل التدريب",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(metric.timestamp),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow("السرعة", "${metric.speed.toStringAsFixed(2)} كم/ساعة"),
              _buildDetailRow("قوة الضربة", "${metric.shotPower.toStringAsFixed(0)} نيوتن"),
              _buildDetailRow("قدرة التحمل", "${metric.stamina.toStringAsFixed(1)}%"),
              _buildDetailRow("قوة الجسم", "${metric.bodyStrength.toStringAsFixed(1)} كجم"),
              _buildDetailRow("الاتزان", "${metric.balance.toStringAsFixed(1)}%"),
              _buildDetailRow("معدل الجهد", "${metric.effortIndex.toStringAsFixed(1)}%"),
              const Divider(),
              _buildDetailRow(
                "النتيجة الإجمالية",
                "${metric.overallScore.toStringAsFixed(1)}%",
                isBold: true,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                "مدة التدريب",
                _formatDuration(metric.trainingDurationSeconds),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerMetricDetailView(
                          playerId: playerId,
                          metricName: "السرعة",
                          currentValue: metric.speed,
                          maxValue: 30.0,
                          icon: Icons.speed,
                          color: Colors.blue,
                          unit: "كم/ساعة",
                        ),
                      ),
                    );
                  },
                  child: const Text("عرض تفاصيل كاملة"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 18 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "${minutes}د ${secs}ث";
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
