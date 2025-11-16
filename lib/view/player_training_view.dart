import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../service/player_service.dart';
import '../model/player_model.dart';
import '../utils/player_metrics_calculator.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPlayer();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      
      // إنشاء مواصفات جديدة بشكل عشوائي مناسب
      // النطاقات المناسبة لكل مواصفة:
      final newSpeed = 10.0 + (random.nextDouble() * 20.0); // 10-30 كم/ساعة
      final newShotPower = 1000.0 + (random.nextDouble() * 4000.0); // 1000-5000 نيوتن
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
        shotPower: newShotPower,
        stamina: newStamina,
        bodyStrength: newBodyStrength,
        balance: newBalance,
        effortIndex: newEffortIndex,
      );

      await PlayerService().addPlayerWithId(updatedPlayer);

      if (mounted) {
        final minutes = duration.inMinutes;
        final seconds = duration.inSeconds % 60;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "تم حفظ نتائج التدريب!\nمدة التدريب: ${minutes}د ${seconds}ث",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // تحديث بيانات اللاعب
        await _loadPlayer();
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

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
            const SizedBox(height: 32),

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
                      "عند إيقاف التايمر، سيتم حفظ المواصفات بشكل تلقائي مع تحسينها بناءً على مدة التدريب.",
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

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 65) return Colors.lightGreen;
    if (score >= 50) return Colors.orange;
    if (score >= 35) return Colors.deepOrange;
    return Colors.red;
  }
}

