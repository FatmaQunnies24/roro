import 'package:flutter/material.dart';
import '../service/player_service.dart';
import '../service/metrics_history_service.dart';
import '../model/player_model.dart';
import '../model/metrics_history_model.dart';
import 'player_metric_detail_view.dart';

class PlayerMetricsListView extends StatelessWidget {
  final String playerId;

  const PlayerMetricsListView({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("جميع التدريبات"),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<PlayerModel>(
        stream: PlayerService().getPlayerById(playerId),
        builder: (context, playerSnapshot) {
          if (playerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!playerSnapshot.hasData) {
            return const Center(child: Text("اللاعب غير موجود"));
          }

          final player = playerSnapshot.data!;

          return StreamBuilder<List<MetricsHistoryModel>>(
            stream: MetricsHistoryService().getAllMetrics(playerId),
            builder: (context, historySnapshot) {
              if (historySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final history = historySnapshot.data ?? [];

              if (history.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "لا توجد تدريبات",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final training = history[index];
                  final trainingNumber = history.length - index; // الأول هو الأحدث
                  
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        _showTrainingDetails(context, training, trainingNumber);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getScoreColor(training.overallScore),
                              radius: 30,
                              child: Text(
                                "$trainingNumber",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "التدريب $trainingNumber",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(training.timestamp),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "مدة التدريب: ${_formatDuration(training.trainingDurationSeconds)}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "النتيجة: ${training.overallScore.toStringAsFixed(1)}%",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _getScoreColor(training.overallScore),
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
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showTrainingDetails(BuildContext context, MetricsHistoryModel training, int trainingNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
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
                "التدريب $trainingNumber",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(training.timestamp),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow("السرعة", "${training.speed.toStringAsFixed(2)} كم/ساعة"),
              _buildDetailRow("قوة الضربة", "${training.shotPower.toStringAsFixed(0)} نيوتن"),
              _buildDetailRow("قدرة التحمل", "${training.stamina.toStringAsFixed(1)}%"),
              _buildDetailRow("قوة الجسم", "${training.bodyStrength.toStringAsFixed(1)} كجم"),
              _buildDetailRow("الاتزان", "${training.balance.toStringAsFixed(1)}%"),
              _buildDetailRow("معدل الجهد", "${training.effortIndex.toStringAsFixed(1)}%"),
              const Divider(),
              _buildDetailRow(
                "النتيجة الإجمالية",
                "${training.overallScore.toStringAsFixed(1)}%",
                isBold: true,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                "مدة التدريب",
                _formatDuration(training.trainingDurationSeconds),
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
}
