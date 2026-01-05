import 'dart:async';
import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../data/global_data.dart';

class GuessingWaitScreen extends StatefulWidget {
  final String gameSessionId;
  final Map<String, dynamic> playerData;

  const GuessingWaitScreen({
    super.key,
    required this.gameSessionId,
    required this.playerData,
  });

  @override
  State<GuessingWaitScreen> createState() => _GuessingWaitScreenState();
}

class _GuessingWaitScreenState extends State<GuessingWaitScreen> {
  Map<String, dynamic>? _currentChallenge;
  bool _loading = true;
  bool _submitting = false;
  final _answerCtrl = TextEditingController();
  Timer? _refreshTimer;
  Timer? _statusTimer;
  bool _allChallengesDone = false;
  final Set<String> _answeredChallengeIds = {};

  @override
  void initState() {
    super.initState();
    _loadChallengesToGuess();
    _startRefreshTimer();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _statusTimer?.cancel();
    _answerCtrl.dispose();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) {
        _refreshTimer?.cancel();
        return;
      }
      // Préserver le challenge actuel s'il est toujours valide
      await _loadChallengesToGuess(preserveCurrent: true);
    });
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) {
        _statusTimer?.cancel();
        return;
      }
      await _checkStatusAndMaybeNavigate();
    });
  }

  Future<void> _checkStatusAndMaybeNavigate() async {
    final statusRes = await ApiService.getGameSessionStatus(widget.gameSessionId);
    if (statusRes['success'] == true) {
      final s = statusRes['data']['status'];
      if (s == 'finished') {
        _statusTimer?.cancel();
        _refreshTimer?.cancel();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          '/results',
          arguments: {
            'gameSessionId': widget.gameSessionId,
            'playerData': widget.playerData,
          },
        );
        return;
      }
    }
    
    // Vérifier aussi si tous les challenges sont résolus (même si le statut n'est pas encore "finished")
    if (_allChallengesDone) {
      final challengesRes = await ApiService.getAllSessionChallenges(widget.gameSessionId);
      if (challengesRes['success'] == true) {
        final data = challengesRes['data'];
        List<dynamic> allChallenges = [];
        if (data is List) {
          allChallenges = data;
        } else if (data is Map && data['items'] is List) {
          allChallenges = data['items'] as List;
        }
        
        // Vérifier si tous les challenges sont résolus
        bool allResolved = true;
        for (final challenge in allChallenges) {
          if (challenge is Map) {
            final isResolved = challenge['is_resolved'] == true;
            if (!isResolved) {
              allResolved = false;
              break;
            }
          }
        }
        
        if (allResolved && allChallenges.isNotEmpty) {
          _statusTimer?.cancel();
          _refreshTimer?.cancel();
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(
            '/results',
            arguments: {
              'gameSessionId': widget.gameSessionId,
              'playerData': widget.playerData,
            },
          );
        }
      }
    }
  }

  Future<void> _loadChallengesToGuess({String? excludeChallengeId, bool preserveCurrent = false}) async {
    final res = await ApiService.getMyChallengesToGuess(widget.gameSessionId);
    if (res['success'] == true) {
      final data = res['data'];
      Map<String, dynamic>? first;
      List<dynamic> list = [];
      
      if (data is List) {
        list = data;
      } else if (data is Map && data['items'] is List) {
        list = data['items'] as List;
      }
      
      // Si on veut préserver le challenge actuel et qu'il est toujours valide, on le garde
      if (preserveCurrent && _currentChallenge != null) {
        final currentId = (_currentChallenge!['id'] ?? _currentChallenge!['_id'] ?? _currentChallenge!['challengeId'])?.toString();
        final isCurrentResolved = _currentChallenge!['is_resolved'] == true;
        final isCurrentAnswered = _answeredChallengeIds.contains(currentId);
        
        // Vérifier si le challenge actuel est toujours dans la liste et toujours valide
        bool currentStillValid = false;
        for (final raw in list) {
          if (raw is Map) {
            final m = Map<String, dynamic>.from(raw as Map);
            final challengeId = (m['id'] ?? m['_id'] ?? m['challengeId'])?.toString();
            if (challengeId == currentId && !isCurrentResolved && !isCurrentAnswered) {
              currentStillValid = true;
              break;
            }
          }
        }
        
        if (currentStillValid) {
          if (mounted) {
            setState(() {
              _loading = false;
            });
          }
          return;
        }
      }
      
      // Sélectionner le premier challenge non résolu ET non répondu
      for (final raw in list) {
        if (raw is Map) {
          final m = Map<String, dynamic>.from(raw as Map);
          final challengeId = (m['id'] ?? m['_id'] ?? m['challengeId'])?.toString();
          final isResolved = m['is_resolved'] == true;
          
          // Exclure les challenges résolus, répondu, ou explicitement exclus
          if (challengeId == excludeChallengeId || isResolved || _answeredChallengeIds.contains(challengeId)) {
            continue;
          }
          
          first = m;
          break;
        }
      }
      
      // Si aucun challenge non résolu, vérifier s'il reste des challenges non exclus
      if (first == null) {
        for (final raw in list) {
          if (raw is Map) {
            final m = Map<String, dynamic>.from(raw as Map);
            final challengeId = (m['id'] ?? m['_id'] ?? m['challengeId'])?.toString();
            if (challengeId != excludeChallengeId && !_answeredChallengeIds.contains(challengeId)) {
              first = m;
              break;
            }
          }
        }
      }
      
      final selectedId = first != null ? (first['id'] ?? first['_id'] ?? first['challengeId']) : null;
      final allDone = (first == null || list.isEmpty);
      
      if (mounted) {
        setState(() {
          _currentChallenge = first;
          _allChallengesDone = allDone;
          _loading = false;
        });
        
        // Si tous les challenges sont terminés, vérifier immédiatement si on peut naviguer
        if (allDone) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _checkStatusAndMaybeNavigate();
            }
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
          _allChallengesDone = true;
        });
      }
    }
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

  Future<void> _submitAnswer() async {
    if (_currentChallenge == null) return;
    if (_answerCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Veuillez saisir une réponse'), backgroundColor: Colors.red[600]),
      );
      return;
    }
    setState(() => _submitting = true);
    final cid = (_currentChallenge!['id'] ?? _currentChallenge!['_id'] ?? _currentChallenge!['challengeId']).toString();
    final answer = _answerCtrl.text.trim();
    
    // Pour l'instant, on envoie is_resolved à false car on ne sait pas si c'est la bonne réponse
    // Le backend devrait vérifier et retourner si c'est résolu ou non
    final res = await ApiService.answerChallenge(
      gameSessionId: widget.gameSessionId,
      challengeId: cid,
      answer: answer,
      isResolved: false,
    );
    
    setState(() => _submitting = false);

    if (res['success'] == true) {
      final responseData = res['data'];
      final isResolved = responseData['is_resolved'] ?? false;
      
      if (!mounted) return;
      
      if (isResolved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Bravo ! Challenge résolu !'), backgroundColor: Colors.green[600]),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Réponse envoyée'), backgroundColor: Colors.blue[600]),
        );
      }
      
      _answerCtrl.clear();
      
      // Ajouter le challenge à la liste des challenges auxquels on a répondu
      _answeredChallengeIds.add(cid);
      
      // Recharger la liste en excluant le challenge auquel on vient de répondre
      await _loadChallengesToGuess(excludeChallengeId: cid);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['error'] ?? 'Erreur lors de l\'envoi'), backgroundColor: Colors.red[600]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase Devineur'),
        backgroundColor: const Color(0xFF667EEA),
        actions: [
          IconButton(onPressed: _loadChallengesToGuess, icon: const Icon(Icons.refresh))
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
            : (_currentChallenge == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_allChallengesDone) ...[
                            const Icon(Icons.check_circle, color: Colors.green, size: 64),
                            const SizedBox(height: 16),
                            const Text(
                              'Tous vos challenges sont terminés !',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'En attente des autres joueurs…',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            const Text(
                              'En attente de votre dessinateur…',
                              style: TextStyle(color: Colors.white70, fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Image à deviner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_getImageUrl(_currentChallenge!) != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _getImageUrl(_currentChallenge!)!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 300,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return SizedBox(
                                          height: 300,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: progress.expectedTotalBytes != null
                                                  ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1)
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 300,
                                        color: Colors.black26,
                                        child: const Center(
                                          child: Text('Impossible de charger l\'image', style: TextStyle(color: Colors.white70)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    height: 300,
                                    color: Colors.black26,
                                    child: const Center(
                                      child: Text('Image non disponible', style: TextStyle(color: Colors.white70)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _answerCtrl,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            labelText: 'Votre réponse',
                            hintText: 'Décrivez ce que vous voyez...',
                            filled: true,
                            fillColor: Colors.white,
                            labelStyle: TextStyle(color: Colors.black54),
                            hintStyle: TextStyle(color: Colors.black38),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _submitting ? null : _submitAnswer,
                          icon: _submitting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send),
                          label: const Text('Envoyer la réponse'),
                        ),
                      ],
                    ),
                  )),
      ),
    );
  }
}
