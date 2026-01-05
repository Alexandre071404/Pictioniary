import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/api_service.dart';
import 'challenge_submission_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String gameSessionId;
  final Map<String, dynamic> playerData;
  final bool createdByCurrentUser;

  const LobbyScreen({
    super.key,
    required this.gameSessionId,
    required this.playerData,
    this.createdByCurrentUser = false,
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
  bool _navigatedToPhase = false;

  @override
  void initState() {
    super.initState();
    _fetchSessionData(showLoading: true);
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      if (!isJoining) {
        _fetchSessionData(showLoading: false);
      }
    });
  }

  Future<void> _fetchSessionData({bool showLoading = false}) async {
    if (showLoading) {
      if (!mounted) return;
      setState(() => isLoading = true);
    }

    try {
      final sessionResult = await ApiService.getGameSession(widget.gameSessionId);
      final statusResult = await ApiService.getGameSessionStatus(widget.gameSessionId);

      if (!mounted) return;

      if (sessionResult['success'] && statusResult['success']) {
        final Map<String, dynamic>? newSessionDataRaw = (sessionResult['data'] is Map) ? (sessionResult['data'] as Map).cast<String, dynamic>() : null;
        final newStatus = statusResult['data']['status'] ?? 'lobby';
        final Map<String, dynamic> previous = sessionData ?? {};

        // Fusion prudente: si l'API ne fournit pas certains champs, conserver ceux existants
        final Map<String, dynamic> newSessionData = {
          ...previous,
          ...?newSessionDataRaw,
        };

        // Si équipes manquantes/vides côté API, préserver l'état antérieur pour éviter le "flash"
        void preserveIfEmpty(String key) {
          final incoming = (newSessionDataRaw != null ? newSessionDataRaw[key] : null);
          final hasIncoming = incoming is List && incoming.isNotEmpty;
          if (!hasIncoming && previous[key] is List && (previous[key] as List).isNotEmpty) {
            newSessionData[key] = (previous[key] as List);
          }
        }
        preserveIfEmpty('red_team');
        preserveIfEmpty('blue_team');
        preserveIfEmpty('redTeam');
        preserveIfEmpty('blueTeam');
        if ((newSessionDataRaw?['teams'] is Map) == false && previous['teams'] is Map) {
          newSessionData['teams'] = previous['teams'];
        }
        if ((newSessionDataRaw?['players'] is List) == false && previous['players'] is List) {
          newSessionData['players'] = previous['players'];
        }
        
        // Récupération des équipes
        final blueTeam = newSessionData['blue_team'] as List? ?? [];
        final redTeam = newSessionData['red_team'] as List? ?? [];
        
        // Vérifie si le joueur courant a déjà rejoint
        final currentPlayerId = widget.playerData['id'] ?? widget.playerData['_id'];
        
        bool playerInSession = _isPlayerInProvidedData(newSessionData, currentPlayerId);
        // Si la nouvelle data ne le confirme pas mais que l'état local le disait, garder true pour éviter l'effet yo-yo
        if (!playerInSession && hasJoined) {
          playerInSession = true;
        }

        if (!mounted) return;
        setState(() {
          sessionData = newSessionData;
          status = newStatus;
          hasJoined = playerInSession;
          if (showLoading) {
            isLoading = false;
          }
        });

        // Si le statut a changé vers challenge
        if (newStatus == 'challenge' && !_navigatedToPhase && mounted) {
          _timer?.cancel();
          _navigatedToPhase = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ChallengeSubmissionScreen(
                gameSessionId: widget.gameSessionId,
                playerData: widget.playerData,
              ),
            ),
          );
          return; // éviter suite
        } else if (newStatus != 'lobby') {
          _showSnackBar('La partie a démarré ! Statut: $newStatus', isSuccess: true);
        }
      } else {
        _showSnackBar('Erreur lors du chargement des données');
        if (showLoading) {
          if (!mounted) return;
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      _showSnackBar('Erreur réseau : $e');
      if (showLoading) {
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    }
  }

  bool _isPlayerInProvidedData(Map<String, dynamic> data, dynamic currentPlayerId) {
    final String currentId = currentPlayerId?.toString() ?? '';
    if (currentId.isEmpty) return false;

    List<dynamic> readTeamList(String key) => (data[key] as List?) ?? const [];

    final List<dynamic> redTeam = readTeamList('red_team').isNotEmpty
        ? readTeamList('red_team')
        : (readTeamList('redTeam'));
    final List<dynamic> blueTeam = readTeamList('blue_team').isNotEmpty
        ? readTeamList('blue_team')
        : (readTeamList('blueTeam'));

    bool listContainsId(List<dynamic> list, String id) {
      for (final entry in list) {
        if (entry is Map) {
          final eId = (entry['id'] ?? entry['_id'])?.toString();
          if (eId == id) return true;
        } else if (entry?.toString() == id) {
          return true;
        }
      }
      return false;
    }

    if (listContainsId(redTeam, currentId) || listContainsId(blueTeam, currentId)) {
      return true;
    }

    // Fallback: via couleur sur l'objet joueur
    final List<dynamic> players = (data['players'] as List?) ?? const [];
    for (final p in players) {
      if (p is Map) {
        final pId = (p['id'] ?? p['_id'])?.toString();
        if (pId == currentId) {
          final pc = (p['color'] ?? p['team'] ?? p['teamColor'])?.toString().toLowerCase();
          if (pc == 'red' || pc == 'blue') return true;
        }
      }
    }
    return false;
  }

  bool _isCurrentPlayerHost() {
    // Si l'écran a été ouvert suite à une création de partie par l'utilisateur courant,
    // on considère qu'il est l'hôte (fallback si l'API ne renvoie pas encore le champ owner/host)
    if (widget.createdByCurrentUser) return true;

    final data = sessionData ?? {};
    final currentId = (widget.playerData['id'] ?? widget.playerData['_id'])?.toString();
    if (currentId == null) return false;

    dynamic extractId(dynamic v) {
      if (v is Map) {
        return (v['id'] ?? v['_id'])?.toString();
      }
      return v?.toString();
    }

    final candidates = [
      extractId(data['owner']),
      extractId(data['owner_id']),
      extractId(data['ownerId']),
      extractId(data['creator']),
      extractId(data['creator_id']),
      extractId(data['creatorId']),
      extractId(data['host']),
      extractId(data['host_id']),
      extractId(data['hostId']),
    ].whereType<String>();

    return candidates.any((id) => id == currentId);
  }

  int _getTotalTeamPlayers() {
    final red = (sessionData?['red_team'] as List?) ?? (sessionData?['redTeam'] as List?) ?? const [];
    final blue = (sessionData?['blue_team'] as List?) ?? (sessionData?['blueTeam'] as List?) ?? const [];
    final Set<String> ids = {
      ...red.map((e) => e is Map ? (e['id'] ?? e['_id'])?.toString() : e?.toString()).whereType<String>(),
      ...blue.map((e) => e is Map ? (e['id'] ?? e['_id'])?.toString() : e?.toString()).whereType<String>(),
    };
    return ids.length;
  }

  Future<void> _joinTeam(String color) async {
    if (isJoining) return;
    
    if (!mounted) return;
    setState(() => isJoining = true);

    try {
      final result = await ApiService.joinGameSession(widget.gameSessionId, color);

      if (result['success']) {
        _showSnackBar('Équipe $color rejointe avec succès !', isSuccess: true);
        // Mise à jour optimiste locale des équipes pour refléter immédiatement l'état
        final currentPlayerId = (widget.playerData['id'] ?? widget.playerData['_id'])?.toString();
        if (currentPlayerId != null) {
          final lower = color.toLowerCase();
          setState(() {
            sessionData ??= {};
            // Préparer les conteneurs d'équipe possibles
            sessionData!['red_team'] = (sessionData!['red_team'] as List?)?.toList() ?? [];
            sessionData!['blue_team'] = (sessionData!['blue_team'] as List?)?.toList() ?? [];
            // Normaliser: retirer l'id de l'autre équipe si présent
            sessionData!['red_team'] = (sessionData!['red_team'] as List)
                .where((e) => (e?.toString() ?? '') != currentPlayerId)
                .toList();
            sessionData!['blue_team'] = (sessionData!['blue_team'] as List)
                .where((e) => (e?.toString() ?? '') != currentPlayerId)
                .toList();
            // Ajouter à la bonne équipe si absent
            final targetList = lower == 'red'
                ? (sessionData!['red_team'] as List)
                : (sessionData!['blue_team'] as List);
            final already = targetList.map((e) => e?.toString()).contains(currentPlayerId);
            if (!already) targetList.add(currentPlayerId);

            // S'assurer que la liste players contient le joueur courant avec sa couleur
            final players = (sessionData!['players'] as List?)?.toList() ?? [];
            final idx = players.indexWhere((p) => ((p['id'] ?? p['_id'])?.toString()) == currentPlayerId);
            if (idx >= 0) {
              players[idx] = {
                ...players[idx],
                'color': lower,
                'team': lower,
              };
            } else {
              players.add({ 'id': currentPlayerId, 'name': widget.playerData['name'], 'color': lower });
            }
            sessionData!['players'] = players;

            hasJoined = true;
          });
        }
        
        // Attendre que l'API se mette à jour
        await Future.delayed(const Duration(seconds: 2));
        
        // Forcer le rafraîchissement
        await _fetchSessionData(showLoading: false);
        
      } else {
        _showSnackBar(result['error'] ?? 'Erreur lors de la jointure de l\'équipe');
      }
    } catch (e) {
      _showSnackBar('Erreur réseau : $e');
    } finally {
      if (!mounted) return;
      setState(() => isJoining = false);
    }
  }

  Future<void> _startGame() async {
    if (!hasJoined) {
      _showSnackBar('Vous devez rejoindre une équipe avant de démarrer');
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final result = await ApiService.startGameSession(widget.gameSessionId);
      
      if (result['success']) {
        _showSnackBar('Partie démarrée !', isSuccess: true);
        await Future.delayed(const Duration(seconds: 2));
        await _fetchSessionData(showLoading: false);
      } else {
        _showSnackBar(result['error'] ?? 'Erreur lors du démarrage de la partie');
      }
    } catch (e) {
      _showSnackBar('Erreur réseau : $e');
    } finally {
      if (!mounted) return;
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

  void _showQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code de la partie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Partagez ce QR code pour que d\'autres joueurs rejoignent la partie',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: widget.gameSessionId,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ID: ${widget.gameSessionId}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  List<dynamic> _getPlayersByColor(String color) {
    final players = sessionData?['players'] as List? ?? [];

    // 1) Essayer différentes formes possibles pour récupérer la liste d'IDs d'équipe
    List<dynamic> rawTeam = [];
    final lower = color.toLowerCase();

    // Forme classique: red_team / blue_team
    if (lower == 'red') {
      rawTeam = (sessionData?['red_team'] as List?) ?? [];
    } else {
      rawTeam = (sessionData?['blue_team'] as List?) ?? [];
    }

    // Variante camelCase: redTeam / blueTeam
    if (rawTeam.isEmpty) {
      if (lower == 'red') {
        rawTeam = (sessionData?['redTeam'] as List?) ?? [];
      } else {
        rawTeam = (sessionData?['blueTeam'] as List?) ?? [];
      }
    }

    // Variante imbriquée: teams: { red: [...], blue: [...] }
    if (rawTeam.isEmpty) {
      final teams = sessionData?['teams'];
      if (teams is Map) {
        rawTeam = (teams[lower] as List?) ?? [];
      }
    }

    // Prélever d'éventuels objets joueurs directement présents dans la liste d'équipe
    final List<Map<String, dynamic>> teamPlayersFromTeamList = rawTeam
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .map((m) => {
              ...m,
              'color': (m['color'] ?? m['team'] ?? m['teamColor'] ?? lower).toString().toLowerCase(),
            })
        .toList();

    // Normaliser en Set<String> d'IDs si possible (la liste peut contenir des ids ou des objets joueurs)
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

    // À partir de players, filtrer par appartenance via IDs
    final List<Map<String, dynamic>> teamPlayersFromPlayers = players.where((p) {
      final playerId = (p['id'] ?? p['_id'])?.toString();
      if (playerId != null && teamIdSet.contains(playerId)) return true;
      final playerColor = (p['color'] ?? p['team'] ?? p['teamColor'])?.toString().toLowerCase();
      return playerColor == lower;
    }).map((p) => Map<String, dynamic>.from(p as Map)).toList();

    // Créer des placeholders pour les IDs présents dans l'équipe mais manquants dans players
    final Set<String> presentIds = {
      ...teamPlayersFromTeamList.map((p) => (p['id'] ?? p['_id'])?.toString()).whereType<String>(),
      ...teamPlayersFromPlayers.map((p) => (p['id'] ?? p['_id'])?.toString()).whereType<String>(),
    };
    final List<Map<String, dynamic>> placeholderPlayers = teamIdSet
        .where((id) => !presentIds.contains(id))
        .map((id) => {
              'id': id,
              'name': 'Joueur $id',
              'color': lower,
            })
        .toList();

    // Fusionner en gardant l'unicité par id/_id
    Map<String, Map<String, dynamic>> byId = {};
    void addAll(List<Map<String, dynamic>> list) {
      for (final p in list) {
        final pid = (p['id'] ?? p['_id'])?.toString();
        if (pid != null) byId[pid] = p;
      }
    }
    addAll(teamPlayersFromTeamList);
    addAll(teamPlayersFromPlayers);
    addAll(placeholderPlayers);

    return byId.values.toList();
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
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              if (isLoading || isJoining) return;
              setState(() => isLoading = true);
              try {
                final res = await ApiService.leaveGameSession(widget.gameSessionId);
                if (!mounted) return;
                if (res['success'] == true) {
                  // Laisser le backend propager la sortie puis revenir
                  await Future.delayed(const Duration(milliseconds: 1200));
                  if (mounted) Navigator.of(context).pop();
                } else {
                  _showSnackBar(res['error'] ?? 'Impossible de quitter la partie');
                }
              } finally {
                if (mounted) setState(() => isLoading = false);
              }
            },
            tooltip: 'Quitter le lobby',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchSessionData(showLoading: false),
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => _showQRCodeDialog(),
            tooltip: 'Afficher le QR Code',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF111827)],
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
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                        children: [
                          Text(
                            'Session: ${widget.gameSessionId}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Statut: $status',
                            style: const TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                          Text(
                            hasJoined ? 'Partie rejointe' : 'Selectionnez une équipe',
                            style: TextStyle(
                              fontSize: 14,
                              color: hasJoined ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        ),
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
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.25)),
                      child: Column(
                        children: [
                          if (!hasJoined && !isJoining)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _joinTeam('red'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
                                    child: const Text('Rouge'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _joinTeam('blue'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16)),
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
                            (() {
                              final isHost = _isCurrentPlayerHost();
                              final total = _getTotalTeamPlayers();
                              if (isHost && total >= 2) {
                                return SizedBox(
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
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  isHost ? 'En attente d\'un autre joueur…' : 'En attente de l\'hôte…',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                                ),
                              );
                            }()),
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