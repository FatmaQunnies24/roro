import 'package:flutter/material.dart';
import 'add_player_view.dart';
import 'players_list_view.dart';

class CoachHomeView extends StatelessWidget {
  final String teamId;

  const CoachHomeView({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Coach Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PlayersListView(teamId: teamId)));
              },
              child: const Text("View Players"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AddPlayerView(teamId: teamId)));
              },
              child: const Text("Add Player"),
            ),
          ],
        ),
      ),
    );
  }
}
