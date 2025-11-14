import 'package:flutter/material.dart';
import '../service/player_service.dart';
import '../model/player_model.dart';
import 'player_details_view.dart';

class PlayersListView extends StatelessWidget {
  final String teamId;
  const PlayersListView({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("قائمة اللاعبين"),
        backgroundColor: Colors.blue[700],
      ),
      body: StreamBuilder<List<PlayerModel>>(
        stream: PlayerService().getPlayersByTeam(teamId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("لا يوجد لاعبين في الفريق حالياً"),
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
                    child: Text(
                      player.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
                  trailing: const Icon(Icons.arrow_forward_ios),
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
