import 'package:flutter/material.dart';
import 'admin_users_tabs_view.dart';
import 'admin_teams_view.dart';

class AdminMainContentView extends StatelessWidget {
  final int currentIndex;

  const AdminMainContentView({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    switch (currentIndex) {
      case 0:
        return const AdminHomeTab();
      case 1:
        return const AdminPlayersTab();
      case 2:
        return const AdminCoachesTab();
      case 3:
        return const AdminAdminsTab();
      case 4:
        return const AdminTeamsTab();
      default:
        return const AdminHomeTab();
    }
  }
}


