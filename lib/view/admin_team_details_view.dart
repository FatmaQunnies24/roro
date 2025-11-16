import 'dart:async';
import 'package:flutter/material.dart';
import '../service/team_service.dart';
import '../service/user_service.dart';
import '../service/player_service.dart';
import '../model/team_model.dart';
import '../model/user_model.dart';
import '../model/player_model.dart';
import 'admin_user_details_view.dart';
import 'player_details_view.dart';
import 'select_users_for_team_view.dart';

class AdminTeamDetailsView extends StatelessWidget {
  final String teamId;

  const AdminTeamDetailsView({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تفاصيل الفريق"),
        backgroundColor: Colors.orange[700],
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("لا يوجد مدربين في هذا الفريق"),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _showAddUserDialog(context, teamId, 'coach');
                                },
                                icon: const Icon(Icons.add),
                                label: const Text("إضافة مدرب"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        ...teamCoaches.map((coach) => Card(
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeUserFromTeam(context, coach.id, 'coach'),
                                    ),
                                    const Icon(Icons.arrow_forward_ios),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminUserDetailsView(userId: coach.id),
                                    ),
                                  );
                                },
                              ),
                            )),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showAddUserDialog(context, teamId, 'coach');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("إضافة مدرب"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // قائمة اللاعبين
                const Text(
                  "اللاعبين",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<UserModel>>(
                  stream: UserService().getUsersByRole('player'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allPlayers = snapshot.data ?? [];
                    final teamPlayers = allPlayers.where((p) => p.teamId == teamId).toList();

                    if (teamPlayers.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("لا يوجد لاعبين في هذا الفريق"),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _showAddUserDialog(context, teamId, 'player');
                                },
                                icon: const Icon(Icons.add),
                                label: const Text("إضافة لاعب"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        ...teamPlayers.map((player) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Text(
                                    player.name[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(player.name),
                                subtitle: Text("المعرف: ${player.id}"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeUserFromTeam(context, player.id, 'player'),
                                    ),
                                    const Icon(Icons.arrow_forward_ios),
                                  ],
                                ),
                                onTap: () async {
                                  // محاولة فتح صفحة معلومات اللاعب
                                  if (player.playerId != null && player.playerId!.isNotEmpty) {
                                    // التحقق من وجود اللاعب أولاً
                                    try {
                                      final playerService = PlayerService();
                                      final playerDoc = await playerService.getPlayerById(player.playerId!).first.timeout(
                                        const Duration(seconds: 5),
                                        onTimeout: () {
                                          throw TimeoutException('انتهت مهلة الاتصال');
                                        },
                                      );
                                      
                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PlayerDetailsView(playerId: player.playerId!),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      // إذا فشل، افتح صفحة معلومات المستخدم
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("معلومات اللاعب غير متوفرة: $e"),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AdminUserDetailsView(userId: player.id),
                                          ),
                                        );
                                      }
                                    }
                                  } else {
                                    // إذا لم يكن هناك playerId، افتح صفحة معلومات المستخدم
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AdminUserDetailsView(userId: player.id),
                                      ),
                                    );
                                  }
                                },
                              ),
                            )),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showAddUserDialog(context, teamId, 'player');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("إضافة لاعب"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
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

  void _showAddUserDialog(BuildContext context, String teamId, String role) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectUsersForTeamView(teamId: teamId, role: role),
      ),
    );

    // إذا تمت الإضافة بنجاح، قم بتحديث الصفحة
    if (result == true && context.mounted) {
      // سيتم التحديث تلقائياً من خلال StreamBuilder
    }
  }

  Future<void> _removeUserFromTeam(BuildContext context, String userId, String role) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("إزالة ${role == 'coach' ? 'مدرب' : 'لاعب'} من الفريق"),
        content: const Text("هل أنت متأكد من إزالة هذا المستخدم من الفريق؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("حذف"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final userService = UserService();
        final teamService = TeamService();
        
        // تحديث teamId إلى قيمة فارغة أو 'none'
        final user = await userService.getUserById(userId);
        if (user != null) {
          final updatedUser = UserModel(
            id: user.id,
            name: user.name,
            role: user.role,
            teamId: '', // إزالة من الفريق
            email: user.email,
            password: user.password,
            playerId: user.playerId,
          );
          await userService.updateUser(updatedUser);
          
          // تحديث عدد المستخدمين في الفريق
          await teamService.updateTeamCounts(teamId);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("تم إزالة ${role == 'coach' ? 'المدرب' : 'اللاعب'} من الفريق"),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
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
}

