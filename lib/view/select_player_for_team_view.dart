import 'package:flutter/material.dart';
import '../service/user_service.dart';
import '../service/player_service.dart';
import '../service/team_service.dart';
import '../model/user_model.dart';
import '../model/player_model.dart';

class SelectPlayerForTeamView extends StatelessWidget {
  final String teamId;

  const SelectPlayerForTeamView({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("اختيار لاعب للفريق"),
        backgroundColor: Colors.blue[700],
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: UserService().getUsersByRole('player'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("لا يوجد لاعبين متاحين"),
            );
          }

          final allPlayers = snapshot.data!;
          // عرض اللاعبين الذين ليس لديهم فريق أو لديهم فريق مختلف
          final availablePlayers = allPlayers.where((u) => u.teamId != teamId).toList();

          if (availablePlayers.isEmpty) {
            return const Center(
              child: Text("لا يوجد لاعبين متاحين لإضافتهم للفريق"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: availablePlayers.length,
            itemBuilder: (context, index) {
              final user = availablePlayers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 4,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user.name),
                  subtitle: Text("المعرف: ${user.id}"),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await _addPlayerToTeam(context, user, teamId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("إضافة"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addPlayerToTeam(BuildContext context, UserModel user, String teamId) async {
    try {
      // تحديث teamId للمستخدم
      final updatedUser = UserModel(
        id: user.id,
        name: user.name,
        role: user.role,
        teamId: teamId,
        playerId: user.playerId,
        email: user.email,
        password: user.password,
      );
      await UserService().updateUser(updatedUser);

      // إذا كان لديه playerId، قم بتحديث teamId في PlayerModel أيضاً
      if (user.playerId != null) {
        try {
          final player = await PlayerService().getPlayerById(user.playerId!).first;
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
          );
          await PlayerService().addPlayerWithId(updatedPlayer);
        } catch (e) {
          // إذا لم يكن هناك PlayerModel، لا بأس
        }
      }

      // تحديث عدد اللاعبين في الفريق
      final teamService = TeamService();
      await teamService.updateTeamCounts(teamId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم إضافة ${user.name} للفريق بنجاح"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطأ: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

