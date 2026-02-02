import 'package:flutter/material.dart';
import '../service/user_service.dart';
import '../service/assessment_service.dart';
import '../model/user_model.dart';
import '../model/assessment_model.dart';
import 'login_view.dart';
import 'assessment_view.dart';
import 'assessment_details_view.dart';
import 'monitoring_settings_view.dart';
import 'assessments_list_view.dart';
import 'analytics_view.dart';

class HomeView extends StatefulWidget {
  final String userId;

  const HomeView({super.key, required this.userId});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

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
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'التقييمات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'التحليل',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // مفتاح ثابت حتى يُحفظ الـ State ولا تُعاد إنشاء الشاشات عند تغيير التبويب
    return IndexedStack(
      index: _currentIndex.clamp(0, 2),
      children: [
        _HomeTabContent(
          key: ValueKey('home_${widget.userId}'),
          userId: widget.userId,
          onShowAllAssessments: () => setState(() => _currentIndex = 1),
        ),
        AssessmentsListView(key: ValueKey('assessments_${widget.userId}'), userId: widget.userId),
        AnalyticsView(key: ValueKey('analytics_${widget.userId}'), userId: widget.userId),
      ],
    );
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

  IconData getStressIcon(String level) {
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

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// محتوى تبويب الرئيسية — جلب واحد للمستخدم والتقييمات (بدون Stream) لتفادي اختفاء البيانات
class _HomeTabContent extends StatefulWidget {
  final String userId;
  final VoidCallback? onShowAllAssessments;

  const _HomeTabContent({
    super.key,
    required this.userId,
    this.onShowAllAssessments,
  });

  @override
  State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> {
  UserModel? _user;
  List<AssessmentModel>? _assessments;
  Object? _userError;
  Object? _assessmentsError;
  bool _loadingUser = true;
  bool _loadingAssessments = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadAssessments();
  }

  Future<void> _loadUser() async {
    if (!mounted) return;
    setState(() {
      _userError = null;
      _loadingUser = true;
    });
    try {
      final user = await UserService().getUserById(widget.userId);
      if (mounted) setState(() {
        _user = user;
        _loadingUser = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _userError = e;
        _loadingUser = false;
      });
    }
  }

  Future<void> _loadAssessments() async {
    if (!mounted) return;
    setState(() {
      _assessmentsError = null;
      _loadingAssessments = true;
    });
    try {
      final list = await AssessmentService().getUserAssessmentsOnce(widget.userId);
      if (mounted) setState(() {
        _assessments = list;
        _loadingAssessments = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _assessmentsError = e;
        _loadingAssessments = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser && _user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_userError != null && _user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ في تحميل البيانات',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUser,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    final user = _user!;
    final assessments = _assessments ?? [];
    final assessmentsFailed = _assessmentsError != null;

    return SingleChildScrollView(
      child: Column(
        children: [
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
                  _loadingAssessments
                      ? 'جاري تحميل التقييمات...'
                      : 'عدد التقييمات: ${assessments.length}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
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
          if (assessmentsFailed && !_loadingAssessments) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'حدث خطأ في تحميل التقييمات',
                          style: TextStyle(color: Colors.orange[900]),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadingAssessments ? null : _loadAssessments,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_loadingAssessments && assessments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (assessments.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'آخر التقييمات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onShowAllAssessments,
                    child: const Text('عرض الكل'),
                  ),
                ],
              ),
            ),
            ...assessments.take(3).map((assessment) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Card(
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _HomeViewState._getStressColor(assessment.predictedStressLevel).withValues(alpha: 0.2),
                      child: Icon(
                        _getStressIcon(assessment.predictedStressLevel),
                        color: _HomeViewState._getStressColor(assessment.predictedStressLevel),
                      ),
                    ),
                    title: Text(
                      _formatDate(assessment.timestamp),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'مستوى التوتر: ${assessment.predictedStressLevel} | نقاط: ${assessment.stressScore.toStringAsFixed(1)}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                ),
              );
            }),
          ] else if (!_loadingAssessments && !assessmentsFailed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assessment_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد تقييمات بعد',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ابدأ بإضافة تقييم جديد',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static IconData _getStressIcon(String level) {
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

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
