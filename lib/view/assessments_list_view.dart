import 'package:flutter/material.dart';
import '../service/assessment_service.dart';
import '../model/assessment_model.dart';
import 'assessment_details_view.dart';

class AssessmentsListView extends StatefulWidget {
  final String userId;

  const AssessmentsListView({super.key, required this.userId});

  @override
  State<AssessmentsListView> createState() => _AssessmentsListViewState();
}

class _AssessmentsListViewState extends State<AssessmentsListView> {
  List<AssessmentModel>? _assessments;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    if (!mounted) return;
    setState(() {
      _error = null;
      _loading = true;
      // لا نمسح _assessments حتى تبقى القائمة ظاهرة أثناء التحديث
    });
    try {
      final list = await AssessmentService().getUserAssessmentsOnce(widget.userId);
      if (mounted) {
        setState(() {
          _assessments = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
          // عند الخطأ نمسح القائمة فقط إذا لم يكن عندنا بيانات أصلاً
          if (_assessments == null) _assessments = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع التقييمات'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadAssessments,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final assessments = _assessments ?? [];
    final hasError = _error != null;
    final hasData = assessments.isNotEmpty;

    // إذا كان هناك خطأ ولا توجد بيانات سابقة — نعرض شاشة الخطأ فقط
    if (hasError && !hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في تحميل التقييمات',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAssessments,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading && _assessments == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (assessments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد تقييمات بعد',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // القائمة (مع شريط خطأ في الأعلى إذا كان هناك خطأ لكن توجد بيانات سابقة)
    final listContent = RefreshIndicator(
      onRefresh: _loadAssessments,
      child: ListView.builder(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isAutoMonitoring ? 'مراقبة تلقائية' : 'تقييم يدوي',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'نقاط التوتر: ${assessment.stressScore.toStringAsFixed(1)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          if (isAutoMonitoring) ...[
                            const SizedBox(height: 4),
                            Text(
                              'مدة: ${_formatDuration(assessment.monitoringDurationSeconds)} | ضغطات: ${assessment.tapCount} | صرخات: ${assessment.screamCount}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (hasError && hasData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.orange[50],
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'حدث خطأ في التحديث. البيانات المعروضة سابقة.',
                        style: TextStyle(color: Colors.orange[900], fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _loadAssessments,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: listContent),
        ],
      );
    }
    return listContent;
  }

  static Color _getStressColor(String level) {
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

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

