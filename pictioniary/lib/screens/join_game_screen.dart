import 'package:flutter/material.dart';
import '../data/api_service.dart';
import 'lobby_screen.dart';

class JoinGameScreen extends StatefulWidget {
  final Map<String, dynamic> playerData;

  const JoinGameScreen({super.key, required this.playerData});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  final _idController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _joinGame(String color) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final gameSessionId = _idController.text.trim();
    final result = await ApiService.joinGameSession(gameSessionId, color);

    if (result['success']) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LobbyScreen(
            gameSessionId: gameSessionId,
            playerData: widget.playerData,
          ),
        ),
      );
    } else {
      _showSnackBar(result['error'] ?? 'Erreur lors de la jointure');
    }

    setState(() => _isLoading = false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[600]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rejoindre une partie')),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'ID de la partie',
                  prefixIcon: Icon(Icons.gamepad),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Entre l\'ID de la partie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _joinGame('red'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Rouge'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _joinGame('blue'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Bleu'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}