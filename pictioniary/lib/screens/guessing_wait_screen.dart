import 'package:flutter/material.dart';

class GuessingWaitScreen extends StatelessWidget {
  final String gameSessionId;
  final Map<String, dynamic> playerData;

  const GuessingWaitScreen({
    super.key,
    required this.gameSessionId,
    required this.playerData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase Devineur'),
        backgroundColor: const Color(0xFF667EEA),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF111827)],
          ),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'En attente de votre dessinateur…',
              style: TextStyle(color: Colors.white70, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}



