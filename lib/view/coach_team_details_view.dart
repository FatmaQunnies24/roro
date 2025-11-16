import 'package:flutter/material.dart';
import '../service/team_service.dart';
import '../service/user_service.dart';
import '../service/player_service.dart';
import '../model/team_model.dart';
import '../model/user_model.dart';
import '../model/player_model.dart';
import 'player_details_view.dart';
import 'coach_assign_player_position_view.dart';
import 'select_users_for_team_view.dart';

class CoachTeamDetailsView extends StatelessWidget {
  final String teamId;

  const CoachTeamDetailsView({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تفاصيل الفريق"),
        backgroundColor: Colors.blue[700],
      ),
      body: FutureBuilder<TeamModel?>(
        future: TeamService().getTeamById(teamId),
        builder: (context, teamSnapshot) {
          if (teamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!teamSnapshot.hasData || teamSnapshot.data == null) {
            return const Center(child: Text("الفريق غير موجود"));
          }

          final team = teamSnapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // معلومات الفريق
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.orange,
                              child: Text(
                                team.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text("المعرف: ${team.id}"),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                "اللاعبين",
                                team.playersCount.toString(),
                                Colors.green,
                                Icons.sports,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                "المدربين",
                                team.coachesCount.toString(),
                                Colors.blue,
                                Icons.person,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // قائمة المدربين
                const Text(
                  "المدربين",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<UserModel>>(
                  stream: UserService().getUsersByRole('coach'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allCoaches = snapshot.data ?? [];
                    final teamCoaches = allCoaches.where((c) => c.teamId == teamId).toList();

                    if (teamCoaches.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: const Text("لا يوجد مدربين في هذا الفريق"),
                        ),
                      );
                    }

                    return Column(
                      children: teamCoaches.map((coach) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  coach.name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(coach.name),
                              subtitle: Text("المعرف: ${coach.id}"),
                              trailing: const Icon(Icons.arrow_forward_ios),
                            ),
                          )).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // قائمة اللاعبين (المستخدمين)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "اللاعبين",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showSelectPlayerDialog(context);
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text("اختر لاعب"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<UserModel>>(
                  stream: UserService().getUsersByRole('player'),
                  builder: (context, usersSnapshot) {
                    if (usersSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allPlayers = usersSnapshot.data ?? [];
                    final teamPlayers = allPlayers.where((u) => u.teamId == teamId).toList();

                    if (teamPlayers.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: const Text("لا يوجد لاعبين في هذا الفريق"),
                        ),
                      );
                    }

                    return Column(
                      children: teamPlayers.map((user) {
                        return FutureBuilder<PlayerModel?>(
                          future: user.playerId != null
                              ? PlayerService().getPlayerById(user.playerId!).first.then((p) => p).catchError((_) => null)
                              : Future.value(null),
                          builder: (context, playerSnapshot) {
                            final player = playerSnapshot.data;
                            final overallScore = player?.overallScore ?? 0.0;
                            final positionType = player?.positionType ?? 'غير محدد';
                            final roleInTeam = player?.roleInTeam ?? 'غير محدد';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 4,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: _getScoreColor(overallScore),
                                  radius: 30,
                                  child: Text(
                                    user.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text("المركز: ${_getPositionArabic(positionType)}"),
                                    Text("الدور: ${_getRoleArabic(roleInTeam)}"),
                                    if (player != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Text("النتيجة: "),
                                          Text(
                                            "${overallScore.toStringAsFixed(1)}%",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _getScoreColor(overallScore),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        value: overallScore / 100.0,
                                        backgroundColor: Colors.grey[300],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _getScoreColor(overallScore),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CoachAssignPlayerPositionView(
                                        userId: user.id,
                                        teamId: teamId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
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

  void _showSelectPlayerDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersForTeamView(
          teamId: teamId,
          role: 'player',
        ),
      ),
    ).then((updated) {
      // تحديث الصفحة عند العودة
      if (updated == true) {
        // سيتم التحديث تلقائياً بواسطة StreamBuilder
      }
    });
  }
}

