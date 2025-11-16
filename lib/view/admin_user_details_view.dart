import 'package:flutter/material.dart';
import '../service/user_service.dart';
import '../service/player_service.dart';
import '../model/user_model.dart';
import '../model/player_model.dart';
import 'player_details_view.dart';

class AdminUserDetailsView extends StatelessWidget {
  final String userId;

  const AdminUserDetailsView({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تفاصيل المستخدم"),
        backgroundColor: Colors.purple[700],
      ),
      body: FutureBuilder<UserModel?>(
        future: UserService().getUserById(userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(child: Text("المستخدم غير موجود"));
          }

          final user = userSnapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // بطاقة المعلومات الأساسية
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
                              backgroundColor: _getRoleColor(user.role),
                              child: Text(
                                user.name[0].toUpperCase(),
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
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Chip(
                                    label: Text(_getRoleArabic(user.role)),
                                    backgroundColor: _getRoleColor(user.role),
                                    labelStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // معلومات المستخدم
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "معلومات المستخدم",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow("المعرف", user.id),
                        _buildInfoRow("الاسم", user.name),
                        _buildInfoRow("نوع المستخدم", _getRoleArabic(user.role)),
                        _buildInfoRow("معرف الفريق", user.teamId),
                        if (user.email != null) _buildInfoRow("البريد الإلكتروني", user.email!),
                        if (user.playerId != null)
                          _buildInfoRow("معرف اللاعب", user.playerId!),
                      ],
                    ),
                  ),
                ),

                // إذا كان لاعب، عرض معلومات اللاعب
                if (user.role == 'player' && user.playerId != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "معلومات اللاعب",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<PlayerModel>(
                            stream: PlayerService().getPlayerById(user.playerId!),
                            builder: (context, playerSnapshot) {
                              if (playerSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              if (!playerSnapshot.hasData) {
                                return const Text("معلومات اللاعب غير متوفرة");
                              }

                              final player = playerSnapshot.data!;
                              return Column(
                                children: [
                                  _buildInfoRow("الاسم", player.name),
                                  _buildInfoRow("المركز", _getPositionArabic(player.positionType)),
                                  _buildInfoRow("الدور", _getRoleArabic(player.roleInTeam)),
                                  _buildInfoRow("السرعة", "${player.speed.toStringAsFixed(1)} كم/س"),
                                  _buildInfoRow("قوة الضربة", "${player.shotPower.toStringAsFixed(0)} نيوتن"),
                                  _buildInfoRow("التحمل", "${player.stamina.toStringAsFixed(1)}%"),
                                  _buildInfoRow("قوة الجسم", "${player.bodyStrength.toStringAsFixed(1)} كجم"),
                                  _buildInfoRow("الاتزان", "${player.balance.toStringAsFixed(1)}%"),
                                  _buildInfoRow("معدل الجهد", "${player.effortIndex.toStringAsFixed(1)}%"),
                                  _buildInfoRow("النتيجة الإجمالية", "${player.overallScore.toStringAsFixed(1)}%"),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                PlayerDetailsView(playerId: user.playerId!),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.visibility),
                                      label: const Text("عرض تفاصيل اللاعب الكاملة"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[700],
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'coach':
        return Colors.blue;
      case 'player':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleArabic(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'أدمن';
      case 'coach':
        return 'مدرب';
      case 'player':
        return 'لاعب';
      case 'starter':
        return 'أساسي';
      case 'reserve':
        return 'احتياطي';
      default:
        return role;
    }
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
}

