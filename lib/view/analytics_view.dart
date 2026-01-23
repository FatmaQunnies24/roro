import 'package:flutter/material.dart';
import '../service/assessment_service.dart';
import '../model/assessment_model.dart';
import 'assessment_details_view.dart';

class AnalyticsView extends StatelessWidget {
  final String userId;

  const AnalyticsView({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحليل والتحسن'),
        backgroundColor: Colors.blue[700],
      ),
      body: StreamBuilder<List<AssessmentModel>>(
        stream: AssessmentService().getUserAssessments(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allAssessments = snapshot.data ?? [];
          
          if (allAssessments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد بيانات للتحليل',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final weekAgo = now.subtract(const Duration(days: 7));
          final monthAgo = now.subtract(const Duration(days: 30));

          final weekAssessments = allAssessments.where((a) => a.timestamp.isAfter(weekAgo)).toList();
          final monthAssessments = allAssessments.where((a) => a.timestamp.isAfter(monthAgo)).toList();
          final last7Assessments = allAssessments.take(7).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // إحصائيات سريعة
                _buildStatsCard(context, 'إجمالي التقييمات', allAssessments.length.toString(), Icons.assessment),
                const SizedBox(height: 12),
                _buildStatsCard(context, 'آخر أسبوع', weekAssessments.length.toString(), Icons.calendar_today),
                const SizedBox(height: 12),
                _buildStatsCard(context, 'آخر شهر', monthAssessments.length.toString(), Icons.date_range),
                
                const SizedBox(height: 24),
                
                // التحسن
                _buildImprovementSection(context, last7Assessments),
                
                const SizedBox(height: 24),
                
                // التقييمات الأخيرة
                _buildRecentAssessmentsSection(context, last7Assessments),
                
                const SizedBox(height: 24),
                
                // التنصائح
                _buildRecommendationsSection(context, allAssessments, weekAssessments),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: Colors.blue[700]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
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
    );
  }

  Widget _buildImprovementSection(BuildContext context, List<AssessmentModel> assessments) {
    if (assessments.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'تحتاج إلى تقييمين على الأقل لرؤية التحسن',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final first = assessments.last;
    final last = assessments.first;
    final improvement = last.stressScore - first.stressScore;
    final isImproving = improvement < 0; // تحسن يعني نقصان في التوتر

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: isImproving ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(
                  'التحسن (آخر 7 تقييمات)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'الأول',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      first.stressScore.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                Icon(
                  isImproving ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isImproving ? Colors.green : Colors.red,
                  size: 30,
                ),
                Column(
                  children: [
                    Text(
                      'الأحدث',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      last.stressScore.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isImproving 
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isImproving ? Icons.check_circle : Icons.warning,
                    color: isImproving ? Colors.green[700] : Colors.red[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isImproving
                          ? 'تحسن بمقدار ${improvement.abs().toStringAsFixed(1)} نقطة'
                          : 'زيادة بمقدار ${improvement.toStringAsFixed(1)} نقطة',
                      style: TextStyle(
                        color: isImproving ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAssessmentsSection(BuildContext context, List<AssessmentModel> assessments) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'آخر 7 تقييمات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...assessments.take(7).map((assessment) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStressColor(assessment.predictedStressLevel).withValues(alpha: 0.2),
                  child: Icon(
                    _getStressIcon(assessment.predictedStressLevel),
                    color: _getStressColor(assessment.predictedStressLevel),
                  ),
                ),
                title: Text(_formatDate(assessment.timestamp)),
                subtitle: Text('نقاط: ${assessment.stressScore.toStringAsFixed(1)}'),
                trailing: Text(
                  assessment.predictedStressLevel,
                  style: TextStyle(
                    color: _getStressColor(assessment.predictedStressLevel),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssessmentDetailsView(assessment: assessment),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(
    BuildContext context,
    List<AssessmentModel> allAssessments,
    List<AssessmentModel> weekAssessments,
  ) {
    final recommendations = <String>[];

    // حساب المتوسطات
    if (weekAssessments.isNotEmpty) {
      final avgStress = weekAssessments.map((a) => a.stressScore).reduce((a, b) => a + b) / weekAssessments.length;
      final avgHours = weekAssessments.map((a) => a.playHoursPerDay).reduce((a, b) => a + b) / weekAssessments.length;
      final highStressCount = weekAssessments.where((a) => a.predictedStressLevel == 'مرتفع').length;

      if (avgStress > 60) {
        recommendations.add('مستوى التوتر مرتفع. حاول تقليل ساعات اللعب.');
      }

      if (avgHours > 6) {
        recommendations.add('عدد ساعات اللعب كبير جداً. حاول تقليله إلى أقل من 4 ساعات يومياً.');
      }

      if (highStressCount > weekAssessments.length / 2) {
        recommendations.add('معظم التقييمات تظهر توتراً مرتفعاً. فكر في استشارة مختص.');
      }

      final nightPlayCount = weekAssessments.where((a) => a.playTime == 'ليل').length;
      if (nightPlayCount > weekAssessments.length / 2) {
        recommendations.add('اللعب ليلاً يزيد التوتر. حاول اللعب في النهار.');
      }

      final competitiveCount = weekAssessments.where((a) => a.gameType == 'تنافسية').length;
      if (competitiveCount > weekAssessments.length * 0.7) {
        recommendations.add('الألعاب التنافسية تزيد التوتر. جرب ألعاباً هادئة.');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('ممتاز! مستويات التوتر جيدة. استمر في الحفاظ على هذا المستوى.');
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  'التنصائح',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
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

  IconData _getStressIcon(String level) {
    switch (level) {
      case 'مرتفع':
        return Icons.warning;
      case 'متوسط':
        return Icons.info;
      case 'منخفض':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

