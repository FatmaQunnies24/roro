import 'package:flutter/material.dart';
import '../service/player_service.dart';
import '../model/player_model.dart';
import '../utils/player_metrics_calculator.dart';

class AddPlayerView extends StatefulWidget {
  final String teamId;

  const AddPlayerView({super.key, required this.teamId});

  @override
  State<AddPlayerView> createState() => _AddPlayerViewState();
}

class _AddPlayerViewState extends State<AddPlayerView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedPosition = 'forward';
  String _selectedRole = 'starter';

  // المدخلات للحسابات
  double _distanceInMeters = 100;
  double _timeInSeconds = 12;
  double _ballMass = 0.43;
  double _ballVelocity = 20;
  double _maxHeartRate = 200;
  double _currentHeartRate = 150;
  double _bodyWeight = 70;
  int _pushUps = 20;
  int _squats = 30;
  int _pullUps = 10;
  double _singleLegStandTime = 30;
  int _balanceLossCount = 2;
  double _weeklyTrainingHours = 10;
  int _completedExercises = 15;
  int _totalExercises = 20;

  // النتائج المحسوبة
  double _speed = 0;
  double _shotPower = 0;
  double _stamina = 0;
  double _bodyStrength = 0;
  double _balance = 0;
  double _effortIndex = 0;

  @override
  void initState() {
    super.initState();
    _calculateMetrics();
  }

  void _calculateMetrics() {
    setState(() {
      _speed = PlayerMetricsCalculator.calculateSpeed(
        distanceInMeters: _distanceInMeters,
        timeInSeconds: _timeInSeconds,
      );

      _shotPower = PlayerMetricsCalculator.calculateShotPower(
        ballMass: _ballMass,
        ballVelocity: _ballVelocity,
      );

      _stamina = PlayerMetricsCalculator.calculateStamina(
        distanceInMeters: _distanceInMeters * 10, // افتراضي 1 كم
        timeInSeconds: _timeInSeconds * 10,
        maxHeartRate: _maxHeartRate,
        currentHeartRate: _currentHeartRate,
      );

      _bodyStrength = PlayerMetricsCalculator.calculateBodyStrength(
        bodyWeight: _bodyWeight,
        pushUps: _pushUps,
        squats: _squats,
        pullUps: _pullUps,
      );

      _balance = PlayerMetricsCalculator.calculateBalance(
        singleLegStandTime: _singleLegStandTime,
        balanceLossCount: _balanceLossCount,
      );

      _effortIndex = PlayerMetricsCalculator.calculateEffortIndex(
        weeklyTrainingHours: _weeklyTrainingHours,
        completedExercises: _completedExercises,
        totalExercises: _totalExercises,
      );
    });
  }

  // إنشاء معرف تلقائي للاعب
  String _generatePlayerId(String name) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final namePart = name.replaceAll(' ', '').toLowerCase();
    final shortName = namePart.length > 6 ? namePart.substring(0, 6) : namePart;
    return 'player_${shortName}_$timestamp';
  }

  Future<void> _addPlayer() async {
    if (_formKey.currentState!.validate()) {
      try {
        final playerService = PlayerService();
        
        // إنشاء معرف تلقائي
        String playerId = _generatePlayerId(_nameController.text.trim());
        
        // التأكد من أن المعرف غير مستخدم
        int attempts = 0;
        while (attempts < 10) {
          try {
            await playerService.getPlayerById(playerId).first.timeout(
              const Duration(milliseconds: 100),
            );
            // إذا وصل هنا، المعرف مستخدم، أنشئ واحد جديد
            playerId = _generatePlayerId(_nameController.text.trim());
            attempts++;
          } catch (e) {
            // المعرف غير مستخدم، يمكن استخدامه
            break;
          }
        }

        // في AddPlayerView، المدرب يضيف لاعب جديد مباشرة
        // لكن يجب أن يكون هناك user موجود أولاً
        // لذا سنستخدم playerId كـ userId مؤقتاً
        final player = PlayerModel(
          id: playerId,
          userId: playerId, // مؤقتاً، يجب أن يكون هناك user موجود
          name: _nameController.text.trim(),
          teamId: widget.teamId,
          positionType: _selectedPosition,
          roleInTeam: _selectedRole,
          speed: _speed,
          shotPower: _shotPower,
          stamina: _stamina,
          bodyStrength: _bodyStrength,
          balance: _balance,
          effortIndex: _effortIndex,
        );

        await playerService.addPlayerWithId(player);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("تم إضافة اللاعب بنجاح"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("حدث خطأ: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إضافة لاعب جديد"),
        backgroundColor: Colors.green[700],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // المعلومات الأساسية
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "المعلومات الأساسية",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "اسم اللاعب",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "يرجى إدخال اسم اللاعب";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedPosition,
                        decoration: const InputDecoration(
                          labelText: "المركز",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'forward', child: Text('هجوم')),
                          DropdownMenuItem(value: 'defender', child: Text('دفاع')),
                          DropdownMenuItem(value: 'midfield', child: Text('وسط')),
                          DropdownMenuItem(value: 'goalkeeper', child: Text('حارس مرمى')),
                          DropdownMenuItem(value: 'substitute', child: Text('احتياطي')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedPosition = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: "الدور في الفريق",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'starter', child: Text('أساسي')),
                          DropdownMenuItem(value: 'reserve', child: Text('احتياطي')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedRole = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // مدخلات الحسابات
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "مدخلات الحسابات",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        "المسافة (متر)",
                        _distanceInMeters,
                        (value) => setState(() {
                          _distanceInMeters = value;
                          _calculateMetrics();
                        }),
                      ),
                      _buildInputField(
                        "الوقت (ثانية)",
                        _timeInSeconds,
                        (value) => setState(() {
                          _timeInSeconds = value;
                          _calculateMetrics();
                        }),
                      ),
                      _buildInputField(
                        "سرعة الكرة (م/ث)",
                        _ballVelocity,
                        (value) => setState(() {
                          _ballVelocity = value;
                          _calculateMetrics();
                        }),
                      ),
                      _buildInputField(
                        "معدل ضربات القلب الحالي",
                        _currentHeartRate,
                        (value) => setState(() {
                          _currentHeartRate = value;
                          _calculateMetrics();
                        }),
                      ),
                      _buildInputField(
                        "وزن الجسم (كجم)",
                        _bodyWeight,
                        (value) => setState(() {
                          _bodyWeight = value;
                          _calculateMetrics();
                        }),
                      ),
                      _buildIntInputField(
                        "عدد تمرينات الضغط",
                        _pushUps,
                        (value) => setState(() {
                          _pushUps = value;
                          _calculateMetrics();
                        }),
                      ),
                      _buildIntInputField(
                        "عدد تمرينات القرفصاء",
                        _squats,
                        (value) => setState(() {
                          _squats = value;
                          _calculateMetrics();
                        }),
                      ),
                      _buildIntInputField(
                        "عدد تمرينات السحب",
                        _pullUps,
                        (value) => setState(() {
                          _pullUps = value;
                          _calculateMetrics();
                        }),
                      ),
                      _buildInputField(
                        "الوقت على قدم واحدة (ثانية)",
                        _singleLegStandTime,
                        (value) => setState(() {
                          _singleLegStandTime = value;
                          _calculateMetrics();
                        }),
                      ),
                      _buildIntInputField(
                        "عدد مرات فقدان الاتزان",
                        _balanceLossCount,
                        (value) => setState(() {
                          _balanceLossCount = value;
                          _calculateMetrics();
                        }),
                      ),
                      _buildInputField(
                        "ساعات التدريب الأسبوعية",
                        _weeklyTrainingHours,
                        (value) => setState(() {
                          _weeklyTrainingHours = value;
                          _calculateMetrics();
                        }),
                      ),
                      _buildIntInputField(
                        "التمارين المكتملة",
                        _completedExercises,
                        (value) => setState(() {
                          _completedExercises = value;
                          _calculateMetrics();
                        }),
                      ),
                      _buildIntInputField(
                        "إجمالي التمارين المطلوبة",
                        _totalExercises,
                        (value) => setState(() {
                          _totalExercises = value;
                          _calculateMetrics();
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // النتائج المحسوبة
              Card(
                elevation: 4,
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "النتائج المحسوبة",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildResultRow("السرعة", "${_speed.toStringAsFixed(1)} كم/س"),
                      _buildResultRow("قوة الضربة", "${_shotPower.toStringAsFixed(0)} نيوتن"),
                      _buildResultRow("التحمل", "${_stamina.toStringAsFixed(1)}%"),
                      _buildResultRow("قوة الجسم", "${_bodyStrength.toStringAsFixed(1)} كجم"),
                      _buildResultRow("الاتزان", "${_balance.toStringAsFixed(1)}%"),
                      _buildResultRow("معدل الجهد", "${_effortIndex.toStringAsFixed(1)}%"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // زر الإضافة
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addPlayer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "إضافة اللاعب",
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

  Widget _buildInputField(String label, double value, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value.toString(),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        onChanged: (val) {
          final newValue = double.tryParse(val);
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }

  Widget _buildIntInputField(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value.toString(),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        onChanged: (val) {
          final newValue = int.tryParse(val);
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
