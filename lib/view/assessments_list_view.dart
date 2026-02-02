import 'package:flutter/material.dart';
import '../service/assessment_service.dart';
import '../model/assessment_model.dart';
import 'assessment_details_view.dart';

class AssessmentsListView extends StatelessWidget {
  final String userId;

  const AssessmentsListView({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع التقييمات'),
        backgroundColor: Colors.blue[700],
      ),
      body: StreamBuilder<List<AssessmentModel>>(
        stream: AssessmentService().getUserAssessments(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final assessments = snapshot.data ?? [];

          if (assessments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assessment_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد تقييمات بعد',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: assessments.length,
            itemBuilder: (context, index) {
              final assessment = assessments[index];
              final isAutoMonitoring = assessment.monitoringDurationSeconds > 0;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssessmentDetailsView(assessment: assessment),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // أيقونة النوع
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isAutoMonitoring 
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Icon(
                            isAutoMonitoring ? Icons.play_circle : Icons.edit,
                            color: isAutoMonitoring ? Colors.green[700] : Colors.blue[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // المعلومات
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isAutoMonitoring ? 'مراقبة تلقائية' : 'تقييم يدوي',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStressColor(assessment.predictedStressLevel).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      assessment.predictedStressLevel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _getStressColor(assessment.predictedStressLevel),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(assessment.timestamp),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'نقاط التوتر: ${assessment.stressScore.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (isAutoMonitoring) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'مدة: ${_formatDuration(assessment.monitoringDurationSeconds)} | ضغطات: ${assessment.tapCount} | صرخات: ${assessment.screamCount}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStressColor(String level) {
    switch (level) {
      case 'مرتفع':
        return Colors.red;
      case 'متوسط':
        return Colors.orange;
      case 'منخفض':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

