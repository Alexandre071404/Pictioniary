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

  String _normalizeString(String str) {
    // Normaliser : minuscules, supprimer accents, espaces multiples, ponctuation
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^\w\s]'), '') // Supprimer ponctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Espaces multiples -> un seul
        .trim();
  }

  bool _isChallengeResolved(Map<String, dynamic> challenge) {
    // Vérifier d'abord le champ is_resolved du backend
    if (challenge['is_resolved'] == true) {
      return true;
    }
    
    // Sinon, comparer les propositions avec le challenge
    final challengeSentence = _formatChallengeSentence(challenge);
    final normalizedChallenge = _normalizeString(challengeSentence);
    final proposals = _extractProposals(challenge);
    
    for (final proposal in proposals) {
      final normalizedProposal = _normalizeString(proposal);
      // Comparer les phrases normalisées
      if (normalizedProposal == normalizedChallenge) {
        return true;
      }
    }
    
    return false;
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

  bool _isPlayerInTeam(dynamic playerId, List<dynamic> team) {
    for (final player in team) {
      final pId = player is Map ? (player['id'] ?? player['_id'])?.toString() : player?.toString();
      if (pId == playerId) {
        return true;
      }
    }
    return false;
  }

  int _countWordsInChallenge(Map<String, dynamic> challenge) {
    // Compter les mots significatifs du challenge (first_word, second_word, third_word, fourth_word, fifth_word)
    int count = 0;
    final words = [
      challenge['first_word'],
      challenge['second_word'],
      challenge['third_word'],
      challenge['fourth_word'],
      challenge['fifth_word'],
    ];
    for (final word in words) {
      if (word != null && word.toString().trim().isNotEmpty) {
        // Exclure les articles et prépositions courants
        final w = word.toString().toLowerCase().trim();
        if (w != 'un' && w != 'une' && w != 'sur' && w != 'dans') {
          count++;
        }
      }
    }
    return count;
  }

  Map<String, dynamic> _getTeamScoreDetails(String teamColor) {
    if (_sessionData == null) {
      return {
        'total': 100,
        'base': 100,
        'gains': 0,
        'losses': 0,
        'details': [],
      };
    }
    
    final teamKey = teamColor == 'red' ? 'red_team' : 'blue_team';
    final team = _sessionData![teamKey] ?? _sessionData![teamKey.replaceAll('_', '')];
    
    int baseScore = 100;
    int totalGains = 0;
    int totalLosses = 0;
    List<Map<String, dynamic>> details = [];
    
    if (team is List) {
      for (final challenge in _challenges) {
        if (challenge is Map) {
          final challengeMap = Map<String, dynamic>.from(challenge);
          final isResolved = _isChallengeResolved(challengeMap);
          final challengerId = challengeMap['challenger_id']?.toString();
          final challengedId = challengeMap['challenged_id']?.toString();
          final challengeSentence = _formatChallengeSentence(challengeMap);
          
          final isGuessingTeam = _isPlayerInTeam(challengedId, team);
          final isCreatingTeam = _isPlayerInTeam(challengerId, team);
          
          // Points gagnés si le challenge est résolu
          if (isGuessingTeam && isResolved) {
            final wordCount = _countWordsInChallenge(challengeMap);
            final pointsGained = wordCount * 25;
            totalGains += pointsGained;
            details.add({
              'type': 'gain',
              'challenge': challengeSentence,
              'points': pointsGained,
              'description': '+$pointsGained pts (${wordCount} mots × 25)',
            });
          }
          
          // Pénalités pour mauvaises réponses (même si le challenge n'est pas résolu)
          if (isGuessingTeam) {
            final proposals = _extractProposals(challengeMap);
            if (proposals.isNotEmpty) {
              final normalizedChallenge = _normalizeString(challengeSentence);
              int wrongAnswers = 0;
              for (final proposal in proposals) {
                final normalizedProposal = _normalizeString(proposal);
                if (normalizedProposal != normalizedChallenge) {
                  wrongAnswers++;
                }
              }
              // Si le challenge est résolu, la dernière proposition est correcte
              if (isResolved && wrongAnswers > 0) {
                wrongAnswers--;
              }
              if (wrongAnswers > 0) {
                totalLosses += wrongAnswers;
                details.add({
                  'type': 'loss',
                  'challenge': challengeSentence,
                  'points': -wrongAnswers,
                  'description': '-$wrongAnswers pts ($wrongAnswers mauvaise${wrongAnswers > 1 ? 's' : ''} réponse${wrongAnswers > 1 ? 's' : ''})',
                });
              }
            }
          }
          
          if (isCreatingTeam) {
            // Pénalités pour régénérations
            final prevImages = challengeMap['previous_images'];
            int regenCount = 0;
            if (prevImages != null) {
              if (prevImages is List) {
                regenCount = (prevImages.length - 1).clamp(0, 2);
              } else if (prevImages is String && prevImages.trim().isNotEmpty) {
                try {
                  final decoded = jsonDecode(prevImages);
                  if (decoded is List) {
                    regenCount = (decoded.length - 1).clamp(0, 2);
                  }
                } catch (_) {}
              }
            }
            if (regenCount > 0) {
              final regenPoints = regenCount * 10;
              totalLosses += regenPoints;
              details.add({
                'type': 'loss',
                'challenge': challengeSentence,
                'points': -regenPoints,
                'description': '-$regenPoints pts ($regenCount régénération${regenCount > 1 ? 's' : ''} × 10)',
              });
            }
          }
        }
      }
    }
    
    return {
      'total': baseScore + totalGains - totalLosses,
      'base': baseScore,
      'gains': totalGains,
      'losses': totalLosses,
      'details': details,
    };
  }

  int _getTeamScore(String teamColor) {
    if (_sessionData == null) return 100; // Score de départ par défaut
    
    final teamKey = teamColor == 'red' ? 'red_team' : 'blue_team';
    final team = _sessionData![teamKey] ?? _sessionData![teamKey.replaceAll('_', '')];
    
    // Vérifier si le backend fournit directement les scores
    final directScore = _sessionData!['${teamColor}_score'] ?? _sessionData!['${teamColor}Score'];
    if (directScore != null) {
      return directScore is int ? directScore : int.tryParse(directScore.toString()) ?? 100;
    }
    
    if (team is List) {
      // Calculer les points basés sur les règles du jeu
      int score = 100; // Score de départ
      
      for (final challenge in _challenges) {
        if (challenge is Map) {
          final challengeMap = Map<String, dynamic>.from(challenge);
          final isResolved = _isChallengeResolved(challengeMap);
          final challengerId = challengeMap['challenger_id']?.toString();
          final challengedId = challengeMap['challenged_id']?.toString();
          
          // L'équipe qui devine (challenged_id) gagne des points si le challenge est résolu
          final isGuessingTeam = _isPlayerInTeam(challengedId, team);
          
          if (isGuessingTeam && isResolved) {
            // +25 points par mot du challenge trouvé
            final wordCount = _countWordsInChallenge(challengeMap);
            score += wordCount * 25;
          }
          
          // L'équipe qui crée le challenge (challenger_id) peut perdre des points pour régénérations
          final isCreatingTeam = _isPlayerInTeam(challengerId, team);
          if (isCreatingTeam) {
            // -10 points par régénération (previous_images.length - 1)
            final prevImages = challengeMap['previous_images'];
            int regenCount = 0;
            if (prevImages != null) {
              if (prevImages is List) {
                regenCount = (prevImages.length - 1).clamp(0, 2); // Max 2 régénérations
              } else if (prevImages is String && prevImages.trim().isNotEmpty) {
                try {
                  final decoded = jsonDecode(prevImages);
                  if (decoded is List) {
                    regenCount = (decoded.length - 1).clamp(0, 2);
                  }
                } catch (_) {}
              }
            }
            score -= regenCount * 10;
          }
          
          // L'équipe qui devine peut perdre des points pour mauvaises réponses
          if (isGuessingTeam) {
            final proposals = _extractProposals(challengeMap);
            final challengeSentence = _formatChallengeSentence(challengeMap);
            final normalizedChallenge = _normalizeString(challengeSentence);
            
            // Compter les mauvaises réponses (propositions qui ne correspondent pas)
            int wrongAnswers = 0;
            for (final proposal in proposals) {
              final normalizedProposal = _normalizeString(proposal);
              if (normalizedProposal != normalizedChallenge) {
                wrongAnswers++;
              }
            }
            // Si le challenge est résolu, la dernière proposition est correcte, donc on soustrait 1
            if (isResolved && wrongAnswers > 0) {
              wrongAnswers--;
            }
            score -= wrongAnswers; // -1 point par mauvaise réponse
          }
        }
      }
      
      return score;
    }
    
    return 100; // Score de départ par défaut
  }

  Widget _buildTeamScoreCard(String teamColor, Color color) {
    final details = _getTeamScoreDetails(teamColor);
    final teamName = teamColor == 'red' ? 'Rouge' : 'Bleue';
    
    return Card(
      color: color.withOpacity(0.2),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          iconColor: Colors.white,
          collapsedIconColor: Colors.white70,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Équipe $teamName',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '${details['total']} points',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score de base
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Score de départ', style: TextStyle(color: Colors.white70)),
                    Text('${details['base']} pts', style: const TextStyle(color: Colors.white)),
                  ],
                ),
                const Divider(color: Colors.white24),
                
                // Gains totaux
                if (details['gains'] > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Points gagnés', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      Text('+${details['gains']} pts', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Pertes totales
                if (details['losses'] > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Points perdus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      Text('-${details['losses']} pts', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Détail par challenge
                if ((details['details'] as List).isNotEmpty) ...[
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  const Text('Détail par challenge :', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...(details['details'] as List<Map<String, dynamic>>).map((detail) {
                    final isGain = detail['type'] == 'gain';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isGain ? Icons.add_circle : Icons.remove_circle,
                            color: isGain ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detail['challenge'] as String,
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  detail['description'] as String,
                                  style: TextStyle(
                                    color: isGain ? Colors.green[300] : Colors.red[300],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
        ),
      ),
    );
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
                    // Scores des équipes avec détails
                    _buildTeamScoreCard('red', Colors.red),
                    const SizedBox(height: 16),
                    _buildTeamScoreCard('blue', Colors.blue),
                    const SizedBox(height: 24),
                    const Text(
                      'Tous les challenges',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Liste des challenges
                    ..._challenges.asMap().entries.map((entry) {
                      final index = entry.key;
                      final challenge = Map<String, dynamic>.from(entry.value as Map);
                      final isResolved = _isChallengeResolved(challenge);
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
                                ...proposals.map((prop) {
                                  final normalizedProp = _normalizeString(prop);
                                  final normalizedChallenge = _normalizeString(_formatChallengeSentence(challenge));
                                  final isCorrect = normalizedProp == normalizedChallenge;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCorrect ? Icons.check_circle : Icons.circle,
                                          color: isCorrect ? Colors.green : Colors.white60,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            prop,
                                            style: TextStyle(
                                              color: isCorrect ? Colors.green[300] : Colors.white60,
                                              fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
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

