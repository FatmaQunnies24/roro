import 'package:flutter/material.dart';
import '../service/assessment_service.dart';
import '../model/assessment_model.dart';
import '../utils/stress_calculator.dart';
import 'assessment_details_view.dart';

class AssessmentView extends StatefulWidget {
  final String userId;

  const AssessmentView({super.key, required this.userId});

  @override
  State<AssessmentView> createState() => _AssessmentViewState();
}

class _AssessmentViewState extends State<AssessmentView> {
  final _formKey = GlobalKey<FormState>();
  final _playHoursController = TextEditingController();
  String _gameType = 'هادئة';
  String _playTime = 'نهار';
  String _playMode = 'جماعي';
  double _stressLevel = 5.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _playHoursController.dispose();
    super.dispose();
  }

  Future<void> _submitAssessment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final playHours = double.tryParse(_playHoursController.text);
        if (playHours == null || playHours < 0 || playHours > 24) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يرجى إدخال عدد ساعات صحيح (0-24)'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        // إنشاء تقييم مؤقت للحساب
        final tempAssessment = AssessmentModel(
          id: '',
          userId: widget.userId,
          timestamp: DateTime.now(),
          playHoursPerDay: playHours,
          gameType: _gameType,
          playTime: _playTime,
          playMode: _playMode,
          stressLevel: _stressLevel,
          predictedStressLevel: '',
          stressScore: 0.0,
        );

        // حساب مستوى التوتر
        final result = StressCalculator.calculateStress(tempAssessment);

        // إنشاء التقييم النهائي
        final assessment = AssessmentModel(
          id: '',
          userId: widget.userId,
          timestamp: DateTime.now(),
          playHoursPerDay: playHours,
          gameType: _gameType,
          playTime: _playTime,
          playMode: _playMode,
          stressLevel: _stressLevel,
          predictedStressLevel: result['predictedStressLevel'] as String,
          stressScore: result['stressScore'] as double,
        );

        // حفظ التقييم
        final assessmentService = AssessmentService();
        final assessmentId = await assessmentService.addAssessment(assessment);

        // تحديث التقييم بالمعرف
        final savedAssessment = AssessmentModel(
          id: assessmentId,
          userId: assessment.userId,
          timestamp: assessment.timestamp,
          playHoursPerDay: assessment.playHoursPerDay,
          gameType: assessment.gameType,
          playTime: assessment.playTime,
          playMode: assessment.playMode,
          stressLevel: assessment.stressLevel,
          predictedStressLevel: assessment.predictedStressLevel,
          stressScore: assessment.stressScore,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AssessmentDetailsView(assessment: savedAssessment),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقييم جديد'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'يرجى الإجابة على الأسئلة التالية:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // عدد ساعات اللعب
              TextFormField(
                controller: _playHoursController,
                decoration: const InputDecoration(
                  labelText: 'عدد ساعات اللعب يوميًا *',
                  hintText: 'مثال: 3.5',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال عدد الساعات';
                  }
                  final hours = double.tryParse(value);
                  if (hours == null || hours < 0 || hours > 24) {
                    return 'يرجى إدخال عدد صحيح بين 0 و 24';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // نوع الألعاب
              DropdownButtonFormField<String>(
                value: _gameType,
                decoration: const InputDecoration(
                  labelText: 'نوع الألعاب *',
                  prefixIcon: Icon(Icons.sports_esports),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'هادئة', child: Text('هادئة')),
                  DropdownMenuItem(value: 'تنافسية', child: Text('تنافسية')),
                ],
                onChanged: (value) {
                  setState(() => _gameType = value!);
                },
              ),
              const SizedBox(height: 24),

              // وقت اللعب
              DropdownButtonFormField<String>(
                value: _playTime,
                decoration: const InputDecoration(
                  labelText: 'وقت اللعب *',
                  prefixIcon: Icon(Icons.wb_sunny),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'نهار', child: Text('نهار')),
                  DropdownMenuItem(value: 'ليل', child: Text('ليل')),
                ],
                onChanged: (value) {
                  setState(() => _playTime = value!);
                },
              ),
              const SizedBox(height: 24),

              // اللعب الفردي أو الجماعي
              DropdownButtonFormField<String>(
                value: _playMode,
                decoration: const InputDecoration(
                  labelText: 'نوع اللعب *',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'فردي', child: Text('فردي')),
                  DropdownMenuItem(value: 'جماعي', child: Text('جماعي')),
                ],
                onChanged: (value) {
                  setState(() => _playMode = value!);
                },
              ),
              const SizedBox(height: 24),

              // المؤشر الذاتي للضغط
              const Text(
                'مستوى الضغط الذي تشعر به بعد اللعب (0-10) *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _stressLevel,
                min: 0,
                max: 10,
                divisions: 10,
                label: _stressLevel.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() => _stressLevel = value);
                },
              ),
              Text(
                'القيمة المختارة: ${_stressLevel.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 32),

              // زر الإرسال
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAssessment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'حساب مستوى التوتر',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

