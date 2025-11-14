import 'package:flutter/material.dart';

class PlayerHomeView extends StatelessWidget {
  final String playerId;
  const PlayerHomeView({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Player Dashboard")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, "/playerDetails", arguments: playerId);
          },
          child: const Text("View My Performance"),
        ),
      ),
    );
  }
}
