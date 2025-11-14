import 'package:flutter/material.dart';
import '../service/player_service.dart';
import '../model/player_model.dart';

class PlayerDetailsView extends StatelessWidget {
  final String playerId;
  const PlayerDetailsView({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Player Details")),
      body: StreamBuilder<PlayerModel>(
        stream: PlayerService().getPlayerById(playerId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final player = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Name: ${player.name}", style: const TextStyle(fontSize: 20)),
              Text("Position: ${player.positionType}"),
              Text("Speed: ${player.speed}"),
              Text("Shot Power: ${player.shotPower}"),
              Text("Stamina: ${player.stamina}"),
              Text("Strength: ${player.bodyStrength}"),
              Text("Balance: ${player.balance}"),
              Text("Effort: ${player.effortIndex}"),
              Text("Overall: ${player.overallScore}"),
              Text("Status: ${player.statusText}", style: const TextStyle(color: Colors.blue)),
            ]),
          );
        },
      ),
    );
  }
}
