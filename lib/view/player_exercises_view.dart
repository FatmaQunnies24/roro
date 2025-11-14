import 'package:flutter/material.dart';
import '../service/player_service.dart';
import '../service/exercise_service.dart';
import '../model/player_model.dart';
import '../model/exercise_model.dart';

class PlayerExercisesView extends StatelessWidget {
  final String playerId;

  const PlayerExercisesView({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("التمارين المناسبة"),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<PlayerModel>(
        stream: PlayerService().getPlayerById(playerId),
        builder: (context, playerSnapshot) {
          if (!playerSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final player = playerSnapshot.data!;

          return FutureBuilder<List<ExerciseModel>>(
            future: ExerciseService().getRecommendedExercisesForPlayer(
              positionType: player.positionType,
              roleInTeam: player.roleInTeam,
              speed: player.speed,
              shotPower: player.shotPower,
              stamina: player.stamina,
              bodyStrength: player.bodyStrength,
              balance: player.balance,
              effortIndex: player.effortIndex,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text("لا توجد تمارين متاحة حالياً"),
                );
              }

              final exercises = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  exercise.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.fitness_center,
                                color: Colors.green[700],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            exercise.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.access_time,
                            "المدة",
                            "${exercise.durationMinutes} دقيقة",
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.repeat,
                            "التكرار",
                            "${exercise.frequencyPerWeek} مرات في الأسبوع",
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.schedule,
                            "أفضل وقت",
                            _getTimeOfDayArabic(exercise.bestTimeOfDay),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.restore,
                            "أيام الراحة",
                            "${exercise.restDaysBetween} يوم بين التمارين",
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: exercise.targetAttributes.map((attr) {
                              return Chip(
                                label: Text(_getAttributeArabic(attr)),
                                backgroundColor: Colors.green[100],
                                labelStyle: const TextStyle(fontSize: 12),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green[700]),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value),
      ],
    );
  }

  String _getTimeOfDayArabic(String timeOfDay) {
    switch (timeOfDay.toLowerCase()) {
      case 'morning':
        return 'صباحاً';
      case 'afternoon':
        return 'ظهراً';
      case 'evening':
        return 'مساءً';
      default:
        return timeOfDay;
    }
  }

  String _getAttributeArabic(String attribute) {
    switch (attribute.toLowerCase()) {
      case 'speed':
        return 'سرعة';
      case 'shotpower':
      case 'shot_power':
        return 'قوة الضربة';
      case 'stamina':
        return 'التحمل';
      case 'bodystrength':
      case 'body_strength':
        return 'قوة الجسم';
      case 'balance':
        return 'الاتزان';
      default:
        return attribute;
    }
  }
}

