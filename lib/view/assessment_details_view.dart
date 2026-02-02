import 'package:flutter/material.dart';
import '../model/assessment_model.dart';

class AssessmentDetailsView extends StatelessWidget {
  final AssessmentModel assessment;

  const AssessmentDetailsView({super.key, required this.assessment});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نتائج التقييم'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة النتيجة الرئيسية
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getStressColor(assessment.predictedStressLevel).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getStressColor(assessment.predictedStressLevel),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getStressIcon(assessment.predictedStressLevel),
                    size: 80,
                    color: _getStressColor(assessment.predictedStressLevel),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'مستوى التوتر المتوقع',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    assessment.predictedStressLevel,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _getStressColor(assessment.predictedStressLevel),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: assessment.stressScore / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStressColor(assessment.predictedStressLevel),
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'النقاط: ${assessment.stressScore.toStringAsFixed(1)} / 100',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            if (assessment.reasons.isNotEmpty || assessment.tips.isNotEmpty) ...[
              const SizedBox(height: 20),
              if (assessment.reasons.isNotEmpty)
                _buildReasonsTipsCard(
                  'أسباب محتملة (هل التوتر عالي أو عصبي؟)',
                  assessment.reasons,
                  Icons.psychology,
                  Colors.orange,
                ),
              if (assessment.reasons.isNotEmpty && assessment.tips.isNotEmpty) const SizedBox(height: 12),
              if (assessment.tips.isNotEmpty)
                _buildReasonsTipsCard(
                  'نصائح',
                  assessment.tips,
                  Icons.lightbulb_outline,
                  Colors.green,
                ),
              const SizedBox(height: 24),
            ],

            // تفاصيل التقييم
            const Text(
              'تفاصيل التقييم',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildDetailCard(
              'التاريخ والوقت',
              _formatDate(assessment.timestamp),
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            _buildDetailCard(
              'عدد ساعات اللعب يوميًا',
              '${assessment.playHoursPerDay} ساعة',
              Icons.access_time,
            ),
            const SizedBox(height: 12),
            _buildDetailCard(
              'نوع الألعاب',
              assessment.gameType,
              Icons.sports_esports,
            ),
            const SizedBox(height: 12),
            _buildDetailCard(
              'وقت اللعب',
              assessment.playTime,
              Icons.wb_sunny,
            ),
            const SizedBox(height: 12),
            _buildDetailCard(
              'نوع اللعب',
              assessment.playMode,
              Icons.people,
            ),
            const SizedBox(height: 12),
            _buildDetailCard(
              'المؤشر الذاتي للضغط',
              '${assessment.stressLevel.toStringAsFixed(1)} / 10',
              Icons.sentiment_satisfied_alt,
            ),

            // بيانات المراقبة التلقائية (إذا كانت متوفرة)
            if (assessment.monitoringDurationSeconds > 0) ...[
              const SizedBox(height: 24),
              const Text(
                'بيانات المراقبة التلقائية',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailCard(
                'مدة المراقبة',
                _formatDuration(assessment.monitoringDurationSeconds),
                Icons.timer,
              ),
              const SizedBox(height: 12),
              _buildDetailCard(
                'عدد الضغطات',
                assessment.tapCount.toString(),
                Icons.touch_app,
              ),
              const SizedBox(height: 12),
              _buildDetailCard(
                'متوسط مستوى الصوت',
                '${assessment.averageSoundLevel.toStringAsFixed(1)}%',
                Icons.volume_up,
              ),
              const SizedBox(height: 12),
              _buildDetailCard(
                'عدد الصرخات',
                assessment.screamCount.toString(),
                Icons.warning,
              ),
              const SizedBox(height: 12),
              _buildDetailCard(
                'عدد الكلمات السيئة التي قالها الطفل',
                assessment.badWordsCount.toString(),
                Icons.block,
              ),
              if (assessment.badWordsCount > 0) ...[
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.block, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Text(
                              'الكلمات السيئة التي قيلت (الطفل)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          assessment.badWordsReport,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Text(
                          'لم يُسجّل أيّة كلمات سيئة',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 32),

            // نصيحة
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'نصيحة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getAdvice(assessment.predictedStressLevel),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // زر العودة
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'العودة',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[700]),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildReasonsTipsCard(String title, String text, IconData icon, MaterialColor color) {
    return Card(
      elevation: 2,
      color: color.withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
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

  String _getAdvice(String level) {
    switch (level) {
      case 'مرتفع':
        return 'مستوى التوتر مرتفع. يُنصح بتقليل ساعات اللعب، واللعب في أوقات النهار، واختيار ألعاب هادئة. كما يُنصح بأخذ فترات راحة منتظمة.';
      case 'متوسط':
        return 'مستوى التوتر متوسط. يُنصح بمراقبة ساعات اللعب واختيار أوقات مناسبة للعب.';
      case 'منخفض':
        return 'مستوى التوتر منخفض. استمر في الحفاظ على هذا المستوى من خلال موازنة وقت اللعب مع الأنشطة الأخرى.';
      default:
        return '';
    }
  }
}

