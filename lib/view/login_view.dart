import 'package:flutter/material.dart';
import 'coach_home_view.dart';
import 'player_home_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose User Type")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CoachHomeView(teamId: "team01")));
                },
                child: const Text("Coach")),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const PlayerHomeView(playerId: "player01")));
                },
                child: const Text("Player")),
          ],
        ),
      ),
    );
  }
}
