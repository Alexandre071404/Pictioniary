import 'package:flutter/material.dart';
import 'dart:developer' as developer; // Ajout pour log
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
  bool _isFetching = false;
  Map<String, dynamic>? _sessionData;
  String _status = 'lobby';

  Future<void> _joinGame(String color) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final gameSessionId = _idController.text.trim();
    Map<String, dynamic> result = await ApiService.joinGameSession(gameSessionId, color);
    
    developer.log('Join result: $result', name: 'JoinGameScreen');

    if (result['success']) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LobbyScreen(
            gameSessionId: gameSessionId,
            playerData: widget.playerData,
          ),
        ),
      );
    } else {
      final errorMsg = (result['error'] ?? '').toString().toLowerCase();
      if (errorMsg.contains('already in game session') || errorMsg.contains('already in game sessions')) {
        // Tenter de quitter puis de rejoindre
        developer.log('Detected already in session, trying leave then re-join', name: 'JoinGameScreen');
        final leave = await ApiService.leaveGameSession(gameSessionId);
        await Future.delayed(const Duration(milliseconds: 800));
        if (leave['success'] == true) {
          result = await ApiService.joinGameSession(gameSessionId, color);
          if (result['success'] == true) {
            await Future.delayed(const Duration(seconds: 2));
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => LobbyScreen(
                  gameSessionId: gameSessionId,
                  playerData: widget.playerData,
                ),
              ),
            );
          } else {
            // Si toujours bloqué, naviguer au lobby directement (car serveur te considère dedans)
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => LobbyScreen(
                  gameSessionId: gameSessionId,
                  playerData: widget.playerData,
                ),
              ),
            );
          }
        } else {
          // Échec du leave: naviguer au lobby pour laisser le lobby gérer l'état
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LobbyScreen(
                gameSessionId: gameSessionId,
                playerData: widget.playerData,
              ),
            ),
          );
        }
      } else {
        _showSnackBar(result['error'] ?? 'Erreur lors de la jointure (vérifiez les logs)');
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _previewSession() async {
    if (_idController.text.trim().isEmpty) {
      _showSnackBar('Entre un identifiant de partie');
      return;
    }
    setState(() => _isFetching = true);
    final id = _idController.text.trim();
    try {
      final session = await ApiService.getGameSession(id);
      final status = await ApiService.getGameSessionStatus(id);
      developer.log('Preview session: ${session.toString()}', name: 'JoinGameScreen');
      developer.log('Preview status: ${status.toString()}', name: 'JoinGameScreen');
      if (session['success']) {
        setState(() {
          _sessionData = Map<String, dynamic>.from(session['data'] as Map);
          _status = status['success'] ? (status['data']['status'] ?? 'lobby') : 'lobby';
        });
      } else {
        _showSnackBar(session['error'] ?? 'Partie introuvable');
      }
    } finally {
      setState(() => _isFetching = false);
    }
  }

  List<Map<String, dynamic>> _extractTeamPlayers(String color) {
    final data = _sessionData ?? {};
    final lower = color.toLowerCase();
    final List players = (data['players'] as List?) ?? const [];

    List rawTeam = [];
    if (lower == 'red') {
      rawTeam = (data['red_team'] as List?) ?? (data['redTeam'] as List?) ?? [];
    } else {
      rawTeam = (data['blue_team'] as List?) ?? (data['blueTeam'] as List?) ?? [];
    }
    if (rawTeam.isEmpty && data['teams'] is Map) {
      rawTeam = ((data['teams'] as Map)[lower] as List?) ?? [];
    }

    final teamPlayersFromTeamList = rawTeam
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .map((m) => {
              ...m,
              'color': (m['color'] ?? m['team'] ?? m['teamColor'] ?? lower).toString().toLowerCase(),
            })
        .toList();

    final Set<String> teamIdSet = rawTeam
        .map((entry) {
          if (entry is Map) {
            final id = entry['id'] ?? entry['_id'];
            return id?.toString();
          }
          return entry?.toString();
        })
        .whereType<String>()
        .toSet();

    final teamPlayersFromPlayers = players.where((p) {
      final playerId = (p['id'] ?? p['_id'])?.toString();
      if (playerId != null && teamIdSet.contains(playerId)) return true;
      final playerColor = (p['color'] ?? p['team'] ?? p['teamColor'])?.toString().toLowerCase();
      return playerColor == lower;
    }).map((p) => Map<String, dynamic>.from(p as Map)).toList();

    final Set<String> presentIds = {
      ...teamPlayersFromTeamList.map((p) => (p['id'] ?? p['_id'])?.toString()).whereType<String>(),
      ...teamPlayersFromPlayers.map((p) => (p['id'] ?? p['_id'])?.toString()).whereType<String>(),
    };
    final placeholderPlayers = teamIdSet
        .where((id) => !presentIds.contains(id))
        .map((id) => {
              'id': id,
              'name': 'Joueur $id',
              'color': lower,
            })
        .toList();

    final Map<String, Map<String, dynamic>> byId = {};
    for (final p in [...teamPlayersFromTeamList, ...teamPlayersFromPlayers, ...placeholderPlayers]) {
      final pid = (p['id'] ?? p['_id'])?.toString();
      if (pid != null) byId[pid] = p;
    }
    return byId.values.toList();
  }

  Widget _buildTeamPreview(String title, String color, Color textColor) {
    final players = _extractTeamPlayers(color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (players.isEmpty)
          const Text('Aucun joueur', style: TextStyle(color: Colors.black54))
        else
          ...players.map((p) => Row(
                children: [
                  Icon(Icons.person, color: textColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p['name'] ?? 'Joueur', overflow: TextOverflow.ellipsis)),
                ],
              )),
      ],
    );
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
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: 'ID de la partie',
                    prefixIcon: const Icon(Icons.gamepad),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _isFetching ? null : _previewSession,
                      tooltip: 'Prévisualiser',
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Entre l\'ID de la partie';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isFetching ? null : _previewSession,
                    icon: _isFetching
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.visibility),
                    label: const Text('Prévisualiser la session'),
                  ),
                ),
                if (_sessionData != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    color: Colors.grey.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Statut: $_status', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildTeamPreview('Équipe Rouge', 'red', Colors.red),
                          const SizedBox(height: 12),
                          _buildTeamPreview('Équipe Bleue', 'blue', Colors.blue),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _joinGame('red'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Rejoindre Rouge'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _joinGame('blue'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Rejoindre Bleu'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}