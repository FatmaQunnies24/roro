import 'package:flutter/material.dart';
import '../service/player_service.dart';
import '../service/team_service.dart';
import '../model/player_model.dart';
import 'player_details_view.dart';

class CoachUnassignedPlayersView extends StatelessWidget {
  final String teamId;

  const CoachUnassignedPlayersView({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("اللاعبين غير المنتسبين"),
        backgroundColor: Colors.orange[700],
      ),
      body: StreamBuilder<List<PlayerModel>>(
        stream: PlayerService().getUnassignedPlayers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "لا يوجد لاعبين غير منتسبين",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final players = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: _getScoreColor(player.overallScore),
                    radius: 30,
                    child: Text(
                      player.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  title: Text(
                    player.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("المركز: ${_getPositionArabic(player.positionType)}"),
                      Text("الدور: ${_getRoleArabic(player.roleInTeam)}"),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text("النتيجة: "),
                          Text(
                            "${player.overallScore.toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(player.overallScore),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: player.overallScore / 100.0,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getScoreColor(player.overallScore),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          _showAddToTeamDialog(context, player);
                        },
                        tooltip: "إضافة للفريق",
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerDetailsView(playerId: player.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddToTeamDialog(BuildContext context, PlayerModel player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("إضافة للفريق"),
        content: Text("هل تريد إضافة ${player.name} للفريق؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // تحديث teamId للاعب
                final updatedPlayer = PlayerModel(
                  id: player.id,
                  userId: player.userId,
                  name: player.name,
                  teamId: teamId,
                  positionType: player.positionType,
                  roleInTeam: player.roleInTeam,
                  speed: player.speed,
                  shotPower: player.shotPower,
                  stamina: player.stamina,
                  bodyStrength: player.bodyStrength,
                  balance: player.balance,
                  effortIndex: player.effortIndex,
                  overallScore: player.overallScore,
                  statusText: player.statusText,
                );
                await PlayerService().addPlayerWithId(updatedPlayer);
                
                // تحديث عدد اللاعبين في الفريق
                final teamService = TeamService();
                await teamService.updateTeamCounts(teamId);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("تم إضافة ${player.name} للفريق بنجاح"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("خطأ: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("إضافة"),
          ),
        ],
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

  String _getPositionArabic(String position) {
    switch (position.toLowerCase()) {
      case 'forward':
        return 'هجوم';
      case 'defender':
        return 'دفاع';
      case 'midfield':
        return 'وسط';
      case 'goalkeeper':
        return 'حارس مرمى';
      case 'substitute':
        return 'احتياطي';
      default:
        return position;
    }
  }

  String _getRoleArabic(String role) {
    switch (role.toLowerCase()) {
      case 'starter':
        return 'أساسي';
      case 'reserve':
        return 'احتياطي';
      default:
        return role;
    }
  }
}

