import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../data/api_service.dart';

class LobbyScreen extends StatefulWidget {
  final String gameSessionId;
  final Map<String, dynamic> playerData;

  const LobbyScreen({
    super.key,
    required this.gameSessionId,
    required this.playerData,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  Map<String, dynamic>? sessionData;
  String status = 'lobby';
  bool isLoading = true;
  bool hasJoined = false;
  bool isJoining = false;
  Timer? _timer;
  String debugInfo = '';

  @override
  void initState() {
    super.initState();
    _logDebug('=== INIT ===');
    _logDebug('Player ID: ${widget.playerData['id'] ?? widget.playerData['_id']}');
    _logDebug('Player Name: ${widget.playerData['name']}');
    _logDebug('Session ID: ${widget.gameSessionId}');
    _fetchSessionData(showLoading: true);
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _logDebug(String message) {
    developer.log(message, name: 'LobbyScreen');
    setState(() {
      debugInfo = '$debugInfo\n$message';
    });
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!isJoining) {
        _fetchSessionData(showLoading: false);
      }
    });
  }

  Future<void> _fetchSessionData({bool showLoading = false}) async {
    if (showLoading) {
      setState(() => isLoading = true);
    }

    try {
      _logDebug('=== FETCH SESSION DATA ===');
      
      final sessionResult = await ApiService.getGameSession(widget.gameSessionId);
      _logDebug('Session Result: ${sessionResult.toString()}');
      
      final statusResult = await ApiService.getGameSessionStatus(widget.gameSessionId);
      _logDebug('Status Result: ${statusResult.toString()}');

      if (sessionResult['success'] && statusResult['success']) {
        final newSessionData = sessionResult['data'];
        final newStatus = statusResult['data']['status'] ?? 'lobby';
        
        _logDebug('New Status: $newStatus');
        _logDebug('Session Data Keys: ${newSessionData?.keys.toList()}');
        
        // Récupération des équipes depuis l'API
        final blueTeam = newSessionData?['blue_team'] as List? ?? [];
        final redTeam = newSessionData?['red_team'] as List? ?? [];
        
        _logDebug('Blue Team: $blueTeam');
        _logDebug('Red Team: $redTeam');
        
        // Vérifie si le joueur courant a déjà rejoint
        final currentPlayerId = widget.playerData['id'] ?? widget.playerData['_id'];
        _logDebug('Current Player ID recherché: $currentPlayerId');
        
        bool playerInSession = false;
        
        // Vérifie dans blue_team
        for (var playerId in blueTeam) {
          _logDebug('Blue - Comparaison: $playerId == $currentPlayerId ?');
          if (playerId.toString() == currentPlayerId.toString()) {
            playerInSession = true;
            _logDebug('MATCH TROUVÉ dans blue_team !');
            break;
          }
        }
        
        // Vérifie dans red_team
        if (!playerInSession) {
          for (var playerId in redTeam) {
            _logDebug('Red - Comparaison: $playerId == $currentPlayerId ?');
            if (playerId.toString() == currentPlayerId.toString()) {
              playerInSession = true;
              _logDebug('MATCH TROUVÉ dans red_team !');
              break;
            }
          }
        }

        _logDebug('Player in session: $playerInSession');

        setState(() {
          sessionData = newSessionData;
          status = newStatus;
          hasJoined = playerInSession;
          if (showLoading) {
            isLoading = false;
          }
        });

        // Si le statut a changé vers challenge
        if (newStatus != 'lobby') {
          _showSnackBar('La partie a démarré ! Statut: $newStatus', isSuccess: true);
        }
      } else {
        _logDebug('ERREUR API');
        _showSnackBar('Erreur lors du chargement des données');
        if (showLoading) {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      _logDebug('EXCEPTION: $e');
      _showSnackBar('Erreur réseau : $e');
      if (showLoading) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _joinTeam(String color) async {
    if (isJoining) return;
    
    setState(() => isJoining = true);
    _logDebug('=== JOIN TEAM $color ===');

    try {
      final result = await ApiService.joinGameSession(widget.gameSessionId, color);
      _logDebug('Join Result: ${result.toString()}');

      if (result['success']) {
        _showSnackBar('Équipe $color rejointe avec succès !', isSuccess: true);
        
        // Attendre que l'API se mette à jour
        await Future.delayed(const Duration(seconds: 2));
        
        // Forcer le rafraîchissement
        await _fetchSessionData(showLoading: false);
        
      } else {
        _logDebug('Join failed: ${result['error']}');
        _showSnackBar(result['error'] ?? 'Erreur lors de la jointure de l\'équipe');
      }
    } catch (e) {
      _logDebug('Join exception: $e');
      _showSnackBar('Erreur réseau : $e');
    } finally {
      setState(() => isJoining = false);
    }
  }

  Future<void> _startGame() async {
    if (!hasJoined) {
      _showSnackBar('Vous devez rejoindre une équipe avant de démarrer');
      return;
    }

    setState(() => isLoading = true);
    _logDebug('=== START GAME ===');

    try {
      final result = await ApiService.startGameSession(widget.gameSessionId);
      _logDebug('Start Result: ${result.toString()}');
      
      if (result['success']) {
        _showSnackBar('Partie démarrée !', isSuccess: true);
        await Future.delayed(const Duration(seconds: 2));
        await _fetchSessionData(showLoading: false);
      } else {
        _showSnackBar(result['error'] ?? 'Erreur lors du démarrage de la partie');
      }
    } catch (e) {
      _logDebug('Start exception: $e');
      _showSnackBar('Erreur réseau : $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green[600] : Colors.red[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<dynamic> _getPlayersByColor(String color) {
    final players = sessionData?['players'] as List? ?? [];
    return players.where((p) {
      final playerColor = (p['color'] ?? '').toString().toLowerCase();
      return playerColor == color.toLowerCase();
    }).toList();
  }

  Widget _buildTeamSection(String teamName, String color, Color textColor) {
    final players = _getPlayersByColor(color);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Équipe $teamName :',
          style: TextStyle(
            fontSize: 16,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (players.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Text(
              'Aucun joueur',
              style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
            ),
          )
        else
          ...players.map((player) => Card(
                color: Colors.white.withOpacity(0.1),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(Icons.person, color: textColor),
                  title: Text(
                    player['name'] ?? 'Joueur inconnu',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'ID: ${player['id'] ?? player['_id'] ?? 'N/A'} | Color: ${player['color']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby de la partie'),
        backgroundColor: const Color(0xFF667EEA),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchSessionData(showLoading: false),
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Debug Info'),
                  content: SingleChildScrollView(
                    child: Text(debugInfo),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Debug',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Session: ${widget.gameSessionId}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Statut: $status',
                            style: const TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                          Text(
                            hasJoined ?'Partie rejointe':'Selectionnez une équipe',
                            style: TextStyle(
                              fontSize: 14,
                              color: hasJoined ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _fetchSessionData(showLoading: false),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTeamSection('Rouge', 'red', Colors.redAccent),
                              const SizedBox(height: 24),
                              _buildTeamSection('Bleue', 'blue', Colors.blueAccent),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Boutons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                      ),
                      child: Column(
                        children: [
                          if (!hasJoined && !isJoining)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _joinTeam('red'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: const Text('Rouge'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _joinTeam('blue'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: const Text('Bleu'),
                                  ),
                                ),
                              ],
                            ),
                          if (isJoining)
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          if (hasJoined && status == 'lobby')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _startGame,
                                icon: const Icon(Icons.play_arrow, size: 28),
                                label: const Text(
                                  'LANCER LA PARTIE',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}