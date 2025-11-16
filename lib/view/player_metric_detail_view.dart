import 'package:flutter/material.dart';
import '../service/metrics_history_service.dart';
import '../model/metrics_history_model.dart';

class PlayerMetricDetailView extends StatelessWidget {
  final String playerId;
  final String metricName;
  final double currentValue;
  final double maxValue;
  final IconData icon;
  final Color color;
  final String unit;

  const PlayerMetricDetailView({
    super.key,
    required this.playerId,
    required this.metricName,
    required this.currentValue,
    required this.maxValue,
    required this.icon,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(metricName),
        backgroundColor: color,
      ),
      body: FutureBuilder<List<MetricsHistoryModel>>(
        future: MetricsHistoryService().getLast7Metrics(playerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data ?? [];
          final values = _getMetricValues(history);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // بطاقة القيمة الحالية
                Card(
                  elevation: 4,
                  color: color.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(icon, size: 64, color: color),
                        const SizedBox(height: 16),
                        Text(
                          "$currentValue $unit",
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          metricName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: (currentValue / maxValue).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 12,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // التحليل
                const Text(
                  "التحليل",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatRow("القيمة الحالية", "$currentValue $unit"),
                        const Divider(),
                        if (values.isNotEmpty) ...[
                          _buildStatRow(
                            "متوسط آخر 7 قياسات",
                            "${(values.reduce((a, b) => a + b) / values.length).toStringAsFixed(2)} $unit",
                          ),
                          const Divider(),
                          _buildStatRow(
                            "أعلى قيمة",
                            "${values.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)} $unit",
                          ),
                          const Divider(),
                          _buildStatRow(
                            "أقل قيمة",
                            "${values.reduce((a, b) => a < b ? a : b).toStringAsFixed(2)} $unit",
                          ),
                          const Divider(),
                          _buildStatRow(
                            "التحسن",
                            values.length > 1
                                ? "${(currentValue - (values.skip(1).reduce((a, b) => a + b) / (values.length - 1))).toStringAsFixed(2)} $unit"
                                : "لا توجد بيانات كافية",
                          ),
                        ] else
                          const Text("لا توجد بيانات سابقة"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // التاريخ
                if (history.isNotEmpty) ...[
                  const Text(
                    "آخر 7 قياسات",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...history.take(7).map((h) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color,
                            child: Text(
                              "${_getMetricValue(h).toStringAsFixed(1)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            "${_getMetricValue(h).toStringAsFixed(2)} $unit",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          subtitle: Text(
                            _formatDate(h.timestamp),
                          ),
                          trailing: Text(
                            _formatDuration(h.trainingDurationSeconds),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<double> _getMetricValues(List<MetricsHistoryModel> history) {
    switch (metricName) {
      case "السرعة":
        return history.map((h) => h.speed).toList();
      case "قوة الضربة":
        return history.map((h) => h.shotPower).toList();
      case "قدرة التحمل":
        return history.map((h) => h.stamina).toList();
      case "قوة الجسم":
        return history.map((h) => h.bodyStrength).toList();
      case "الاتزان":
        return history.map((h) => h.balance).toList();
      case "معدل الجهد":
        return history.map((h) => h.effortIndex).toList();
      default:
        return [];
    }
  }

  double _getMetricValue(MetricsHistoryModel history) {
    switch (metricName) {
      case "السرعة":
        return history.speed;
      case "قوة الضربة":
        return history.shotPower;
      case "قدرة التحمل":
        return history.stamina;
      case "قوة الجسم":
        return history.bodyStrength;
      case "الاتزان":
        return history.balance;
      case "معدل الجهد":
        return history.effortIndex;
      default:
        return 0.0;
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
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
}

