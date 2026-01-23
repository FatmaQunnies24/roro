import 'package:flutter/material.dart';
import '../service/user_service.dart';
import '../service/assessment_service.dart';
import '../model/user_model.dart';
import '../model/assessment_model.dart';
import 'login_view.dart';
import 'assessment_view.dart';
import 'assessment_details_view.dart';
import 'monitoring_settings_view.dart';

class HomeView extends StatefulWidget {
  final String userId;

  const HomeView({super.key, required this.userId});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _hasStartedMonitoring = false;

  @override
  void initState() {
    super.initState();
    // بدء المراقبة تلقائياً بعد تحميل الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasStartedMonitoring && mounted) {
        _hasStartedMonitoring = true;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MonitoringSettingsView(userId: widget.userId),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقييم التوتر المرتبط بالألعاب الرقمية'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginView()),
                (route) => false,
              );
            },
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: FutureBuilder<UserModel?>(
        future: UserService().getUserById(widget.userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = userSnapshot.data;
          if (user == null) {
            return const Center(child: Text('المستخدم غير موجود'));
          }

          return StreamBuilder<List<AssessmentModel>>(
            stream: AssessmentService().getUserAssessments(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final assessments = snapshot.data ?? [];

              return Column(
                children: [
                  // معلومات المستخدم
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مرحباً، ${user.name}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'عدد التقييمات: ${assessments.length}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // زر بدء المراقبة التلقائية
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MonitoringSettingsView(userId: widget.userId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text(
                          'بدء المراقبة التلقائية',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // زر إضافة تقييم يدوي
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssessmentView(userId: widget.userId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text(
                          'تقييم يدوي',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // قائمة التقييمات
                  Expanded(
                    child: assessments.isEmpty
                        ? Center(
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
                                const SizedBox(height: 8),
                                Text(
                                  'ابدأ بإضافة تقييم جديد',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: assessments.length,
                            itemBuilder: (context, index) {
                              final assessment = assessments[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getStressColor(assessment.predictedStressLevel),
                                    child: Icon(
                                      _getStressIcon(assessment.predictedStressLevel),
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    'تقييم ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'التاريخ: ${_formatDate(assessment.timestamp)}',
                                      ),
                                      Text(
                                        'مستوى التوتر: ${assessment.predictedStressLevel}',
                                        style: TextStyle(
                                          color: _getStressColor(assessment.predictedStressLevel),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AssessmentDetailsView(
                                          assessment: assessment,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
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
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

