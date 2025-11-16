import 'package:flutter/material.dart';
import '../service/user_service.dart';
import '../model/user_model.dart';
import 'admin_user_details_view.dart';

class AdminUsersTabsView extends StatelessWidget {
  const AdminUsersTabsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabBarView(
      children: [
        AdminHomeTab(),
        AdminPlayersTab(),
        AdminCoachesTab(),
        AdminAdminsTab(),
      ],
    );
  }
}

// تبويب الرئيسية
class AdminHomeTab extends StatelessWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: UserService().getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allUsers = snapshot.data ?? [];
        final playersCount = allUsers.where((u) => u.role == 'player').length;
        final coachesCount = allUsers.where((u) => u.role == 'coach').length;
        final adminsCount = allUsers.where((u) => u.role == 'admin').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة ترحيبية
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        size: 64,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "مرحباً أيها الأدمن",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "لوحة التحكم الرئيسية",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.purple[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // إحصائيات
              const Text(
                "الإحصائيات",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "اللاعبين",
                      playersCount.toString(),
                      Colors.green,
                      Icons.sports,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      "المدربين",
                      coachesCount.toString(),
                      Colors.blue,
                      Icons.person,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "الأدمن",
                      adminsCount.toString(),
                      Colors.purple,
                      Icons.admin_panel_settings,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      "إجمالي المستخدمين",
                      allUsers.length.toString(),
                      Colors.orange,
                      Icons.people,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// تبويب اللاعبين
class AdminPlayersTab extends StatelessWidget {
  const AdminPlayersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: UserService().getUsersByRole('player'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("لا يوجد لاعبين"),
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
                  backgroundColor: Colors.green,
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
                    Text("المعرف: ${player.id}"),
                    if (player.email != null) Text("البريد: ${player.email}"),
                    Text("الفريق: ${player.teamId}"),
                    if (player.playerId != null)
                      Text("معرف اللاعب: ${player.playerId}"),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminUserDetailsView(userId: player.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// تبويب المدربين
class AdminCoachesTab extends StatelessWidget {
  const AdminCoachesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: UserService().getUsersByRole('coach'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("لا يوجد مدربين"),
          );
        }

        final coaches = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: coaches.length,
          itemBuilder: (context, index) {
            final coach = coaches[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    coach.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  coach.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("المعرف: ${coach.id}"),
                    if (coach.email != null) Text("البريد: ${coach.email}"),
                    Text("الفريق: ${coach.teamId}"),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminUserDetailsView(userId: coach.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// تبويب الأدمن
class AdminAdminsTab extends StatelessWidget {
  const AdminAdminsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: UserService().getUsersByRole('admin'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("لا يوجد أدمن"),
          );
        }

        final admins = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: admins.length,
          itemBuilder: (context, index) {
            final admin = admins[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Text(
                    admin.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  admin.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("المعرف: ${admin.id}"),
                    if (admin.email != null) Text("البريد: ${admin.email}"),
                    Text("الفريق: ${admin.teamId}"),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminUserDetailsView(userId: admin.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}


