import 'package:flutter/material.dart';
import 'coach_tabs_view.dart';

class CoachMainContentView extends StatelessWidget {
  final int currentIndex;
  final String teamId;

  const CoachMainContentView({
    super.key,
    required this.currentIndex,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    switch (currentIndex) {
      case 0:
        return CoachHomeTab(teamId: teamId);
      case 1:
        return CoachTeamsTab(teamId: teamId);
      case 2:
        return CoachPlayersTab(teamId: teamId);
      default:
        return CoachHomeTab(teamId: teamId);
    }
  }
}

