import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../service/player_service.dart';
import '../service/metrics_history_service.dart';
import '../model/player_model.dart';
import '../model/metrics_history_model.dart';
import '../utils/player_metrics_calculator.dart';
import 'player_metrics_list_view.dart';

class PlayerTrainingView extends StatefulWidget {
  final String playerId;

  const PlayerTrainingView({super.key, required this.playerId});

  @override
  State<PlayerTrainingView> createState() => _PlayerTrainingViewState();
}

class _PlayerTrainingViewState extends State<PlayerTrainingView> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  PlayerModel? _player;
  DateTime? _startTime;

  // حقول إدخال قوة الضربة
  final _ballMassController = TextEditingController(text: '0.43');
  final _ballVelocityController = TextEditingController(text: '20');

  @override
  void initState() {
    super.initState();
    _loadPlayer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ballMassController.dispose();
    _ballVelocityController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayer() async {
    try {
      final player = await PlayerService().getPlayerById(widget.playerId).first;
      setState(() {
        _player = player;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطأ في تحميل بيانات اللاعب: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _startTime = DateTime.now();
      _elapsedSeconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopTimer() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });

    if (_player != null && _startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      await _saveTrainingResults(duration);
    }
  }

  Future<void> _saveTrainingResults(Duration duration) async {
    if (_player == null) return;

    try {
      final random = Random();
      
      // حساب قوة الضربة من المدخلات
      final ballMass = double.tryParse(_ballMassController.text) ?? 0.43;
      final ballVelocity = double.tryParse(_ballVelocityController.text) ?? 20.0;
      final calculatedShotPower = PlayerMetricsCalculator.calculateShotPower(
        ballMass: ballMass,
        ballVelocity: ballVelocity,
      );
      
      // باقي الأرقام عشوائية
      final newSpeed = 10.0 + (random.nextDouble() * 20.0); // 10-30 كم/ساعة
      final newStamina = 20.0 + (random.nextDouble() * 80.0); // 20-100%
      final newBodyStrength = 50.0 + (random.nextDouble() * 150.0); // 50-200 كجم
      final newBalance = 20.0 + (random.nextDouble() * 80.0); // 20-100%
      final newEffortIndex = 20.0 + (random.nextDouble() * 80.0); // 20-100%

      final updatedPlayer = PlayerModel(
        id: _player!.id,
        userId: _player!.userId,
        name: _player!.name,
        teamId: _player!.teamId,
        positionType: _player!.positionType,
        roleInTeam: _player!.roleInTeam,
        speed: newSpeed,
        shotPower: calculatedShotPower, // قوة الضربة المحسوبة
        stamina: newStamina,
        bodyStrength: newBodyStrength,
        balance: newBalance,
        effortIndex: newEffortIndex,
      );

      await PlayerService().addPlayerWithId(updatedPlayer);

      // حفظ في التاريخ
      final historyService = MetricsHistoryService();
      final history = MetricsHistoryModel(
        id: '', // سيتم إنشاؤه تلقائياً
        playerId: _player!.id,
        timestamp: DateTime.now(),
        speed: newSpeed,
        shotPower: calculatedShotPower,
        stamina: newStamina,
        bodyStrength: newBodyStrength,
        balance: newBalance,
        effortIndex: newEffortIndex,
        overallScore: updatedPlayer.overallScore,
        trainingDurationSeconds: duration.inSeconds,
      );
      await historyService.addMetricsHistory(history);

      if (mounted) {
        final minutes = duration.inMinutes;
        final seconds = duration.inSeconds % 60;
        
        // عرض نتائج الأداء
        _showPerformanceResults(updatedPlayer, duration);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطأ في حفظ النتائج: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPerformanceResults(PlayerModel player, Duration duration) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("نتائج التدريب"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "مدة التدريب: ${duration.inMinutes}د ${duration.inSeconds % 60}ث",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                "المواصفات الجديدة:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildResultRow("السرعة", "${player.speed.toStringAsFixed(2)} كم/ساعة"),
              _buildResultRow("قوة الضربة", "${player.shotPower.toStringAsFixed(0)} نيوتن"),
              _buildResultRow("قدرة التحمل", "${player.stamina.toStringAsFixed(1)}%"),
              _buildResultRow("قوة الجسم", "${player.bodyStrength.toStringAsFixed(1)} كجم"),
              _buildResultRow("الاتزان", "${player.balance.toStringAsFixed(1)}%"),
              _buildResultRow("معدل الجهد", "${player.effortIndex.toStringAsFixed(1)}%"),
              const Divider(),
              _buildResultRow(
                "النتيجة الإجمالية",
                "${player.overallScore.toStringAsFixed(1)}%",
                isBold: true,
              ),
              const SizedBox(height: 8),
              Text(
                "تحليل الأداء: ${player.statusText}",
                style: TextStyle(
                  color: _getScoreColor(player.overallScore),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerMetricsListView(playerId: widget.playerId),
                ),
              );
            },
            child: const Text("عرض جميع المواصفات"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // العودة لصفحة معلومات اللاعب
            },
            child: const Text("تم"),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 65) return Colors.lightGreen;
    if (score >= 50) return Colors.orange;
    if (score >= 35) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_player == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("التدريب"),
          backgroundColor: Colors.orange[700],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("التدريب"),
        backgroundColor: Colors.orange[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // بطاقة معلومات اللاعب
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _player!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "النتيجة الحالية: ${_player!.overallScore.toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 18,
                        color: _getScoreColor(_player!.overallScore),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // حقول إدخال قوة الضربة
            if (!_isRunning) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "إدخال بيانات قوة الضربة",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ballMassController,
                        decoration: const InputDecoration(
                          labelText: "كتلة الكرة (كجم)",
                          hintText: "0.43",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ballVelocityController,
                        decoration: const InputDecoration(
                          labelText: "سرعة الكرة (م/ث)",
                          hintText: "20",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // التايمر
            Card(
              elevation: 8,
              color: _isRunning ? Colors.green[50] : Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text(
                      "مدة التدريب",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _formatTime(_elapsedSeconds),
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: _isRunning ? Colors.green[700] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // أزرار التحكم
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRunning)
                  ElevatedButton.icon(
                    onPressed: _startTimer,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("ابدأ التدريب"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _stopTimer,
                    icon: const Icon(Icons.stop),
                    label: const Text("إيقاف التدريب"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // معلومات
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, size: 32, color: Colors.blue),
                    const SizedBox(height: 8),
                    const Text(
                      "ملاحظة",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRunning
                          ? "التدريب قيد التشغيل..."
                          : "أدخل بيانات قوة الضربة ثم ابدأ التدريب. عند الإيقاف، سيتم حساب قوة الضربة من المدخلات وباقي المواصفات ستكون عشوائية.",
                      textAlign: TextAlign.center,
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
        ),
      ),
    );
  }
}
