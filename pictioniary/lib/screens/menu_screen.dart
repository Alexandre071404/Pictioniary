import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../widgets/menu_button.dart';
import 'login_screen.dart';
import 'lobby_screen.dart';
import 'join_game_screen.dart'; 
import 'docs_screen.dart';

class MenuScreen extends StatelessWidget {
  final Map<String, dynamic> playerData;

  const MenuScreen({super.key, required this.playerData});

  @override
  Widget build(BuildContext context) {
    final playerName = playerData['name'] ?? 'Joueur';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Salut $playerName !",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        "Prêt à jouer ?",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                MenuButton(
                  icon: Icons.add_circle,
                  title: "Créer une partie",
                  subtitle: "Lance une nouvelle partie",
                  color: const Color(0xFF10B981),
                  onTap: () => _createGameSession(context),
                ),

                const SizedBox(height: 20),

                MenuButton(
                  icon: Icons.groups,
                  title: "Rejoindre une partie",
                  subtitle: "Entre dans une partie existante",
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => JoinGameScreen(playerData: playerData),
                      ),
                    );
                  },
                ),

                const Spacer(),

                MenuButton(
                  icon: Icons.description,
                  title: "Documentation",
                  subtitle: "Documentation technique",
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DocsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  label: const Text(
                    "Se déconnecter",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createGameSession(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ApiService.createGameSession();
      Navigator.of(context).pop();

      if (result['success']) {
        final gameSessionData = result['data'];
        final gameSessionId = gameSessionData['id'] ?? gameSessionData['_id'] ?? gameSessionData['gameSessionId'];

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LobbyScreen(
              gameSessionId: gameSessionId.toString(),
              playerData: playerData,
              createdByCurrentUser: true,
            ),
          ),
        );
      } else {
        _showSnackBar(context, result['error'] ?? 'Erreur lors de la création de la partie');
      }
    } catch (_) {
      Navigator.of(context).pop();
      _showSnackBar(context, 'Erreur de connexion');
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green[600] : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isSuccess ? 4 : 3),
      ),
    );
  }
}