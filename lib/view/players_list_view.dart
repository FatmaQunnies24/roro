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
      appBar: AppBar(title: const Text("Players List")),
      body: StreamBuilder<List<PlayerModel>>(
        stream: PlayerService().getPlayersByTeam(teamId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final players = snapshot.data!;
          return ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final p = players[index];
              return ListTile(
                title: Text(p.name),
                subtitle: Text("Position: ${p.positionType} | Score: ${p.overallScore}"),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PlayerDetailsView(playerId: p.id)));
                },
              );
            },
          );
        },
      ),
    );
  }
}
