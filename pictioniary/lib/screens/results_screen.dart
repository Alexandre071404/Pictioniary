import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../data/global_data.dart';

class ResultsScreen extends StatefulWidget {
  final String gameSessionId;
  final Map<String, dynamic> playerData;

  const ResultsScreen({
    super.key,
    required this.gameSessionId,
    required this.playerData,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<dynamic> _challenges = [];
  Map<String, dynamic>? _sessionData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _loading = true);
    
    // Charger les challenges et les données de session
    final challengesRes = await ApiService.getAllSessionChallenges(widget.gameSessionId);
    final sessionRes = await ApiService.getGameSession(widget.gameSessionId);
    
    if (challengesRes['success'] == true) {
      final data = challengesRes['data'];
      if (data is List) {
        _challenges = data;
      } else if (data is Map && data['items'] is List) {
        _challenges = data['items'] as List;
      }
    }
    
    if (sessionRes['success'] == true) {
      _sessionData = sessionRes['data'] as Map<String, dynamic>?;
    }
    
    setState(() => _loading = false);
  }

  String _formatChallengeSentence(Map<String, dynamic> challenge) {
    final fw = challenge['first_word'] ?? '';
    final sw = challenge['second_word'] ?? '';
    final tw = challenge['third_word'] ?? '';
    final fw2 = challenge['fourth_word'] ?? '';
    final fifth = challenge['fifth_word'] ?? '';
    return [fw, sw, tw, fw2, fifth].where((p) => p.toString().isNotEmpty).join(' ');
  }

  List<String> _extractProposals(Map<String, dynamic> challenge) {
    final raw = challenge['proposals'] ?? [];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        return raw.split(',').map((e) => e.trim()).toList();
      }
    }
    return [];
  }

  String? _getImageUrl(Map<String, dynamic> challenge) {
    final path = challenge['image_path'] ?? challenge['imageUrl'] ?? challenge['image'];
    if (path == null || path.toString().isEmpty) return null;
    final url = path.toString();
    if (url.startsWith('http')) return url;
    final sanitizedBase = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final normalizedPath = url.startsWith('/') ? url : '/$url';
    return '$sanitizedBase$normalizedPath';
  }

  int _getTeamScore(String teamColor) {
    if (_sessionData == null) return 0;
    final teamKey = teamColor == 'red' ? 'red_team' : 'blue_team';
    final team = _sessionData![teamKey] ?? _sessionData![teamKey.replaceAll('_', '')];
    if (team is List) {
      // Calculer les points basés sur les challenges résolus
      int score = 100; // Score de départ
      for (final challenge in _challenges) {
        if (challenge is Map) {
          final isResolved = challenge['is_resolved'] == true;
          final challengerId = challenge['challenger_id']?.toString();
          final challengedId = challenge['challenged_id']?.toString();
          
          // Vérifier si ce challenge concerne cette équipe
          bool isTeamChallenge = false;
          for (final player in team) {
            final playerId = player is Map ? (player['id'] ?? player['_id'])?.toString() : player?.toString();
            if (playerId == challengerId || playerId == challengedId) {
              isTeamChallenge = true;
              break;
            }
          }
          
          if (isTeamChallenge && isResolved) {
            score += 25; // Points pour challenge résolu
          }
        }
      }
      return score;
    }
    return _sessionData!['${teamColor}_score'] ?? _sessionData!['${teamColor}Score'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats de la partie'),
        backgroundColor: const Color(0xFF667EEA),
        actions: [
          IconButton(onPressed: _loadResults, icon: const Icon(Icons.refresh))
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
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Scores des équipes
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.red.withOpacity(0.2),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Text('Équipe Rouge', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_getTeamScore('red')} points',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            color: Colors.blue.withOpacity(0.2),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Text('Équipe Bleue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_getTeamScore('blue')} points',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tous les challenges',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Liste des challenges
                    ..._challenges.asMap().entries.map((entry) {
                      final index = entry.key;
                      final challenge = entry.value as Map<String, dynamic>;
                      final isResolved = challenge['is_resolved'] == true;
                      final proposals = _extractProposals(challenge);
                      final imageUrl = _getImageUrl(challenge);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Challenge ${index + 1}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isResolved ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isResolved ? 'Résolu' : 'Non résolu',
                                      style: TextStyle(
                                        color: isResolved ? Colors.green[300] : Colors.red[300],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _formatChallengeSentence(challenge),
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              if (imageUrl != null) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 200,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 200,
                                      color: Colors.black26,
                                      child: const Center(
                                        child: Text('Image non disponible', style: TextStyle(color: Colors.white70)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (proposals.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Propositions :',
                                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                ...proposals.map((prop) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• $prop',
                                    style: const TextStyle(color: Colors.white60),
                                  ),
                                )),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
      ),
    );
  }
}

