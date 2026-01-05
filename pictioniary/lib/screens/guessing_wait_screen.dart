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

  @override
  void initState() {
    super.initState();
    _loadChallengesToGuess();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
      await _loadChallengesToGuess();
    });
  }

  Future<void> _loadChallengesToGuess() async {
    final res = await ApiService.getMyChallengesToGuess(widget.gameSessionId);
    if (res['success'] == true) {
      final data = res['data'];
      Map<String, dynamic>? first;
      if (data is List && data.isNotEmpty) {
        first = Map<String, dynamic>.from(data.first as Map);
      } else if (data is Map && data['items'] is List && (data['items'] as List).isNotEmpty) {
        first = Map<String, dynamic>.from((data['items'] as List).first as Map);
      }
      if (mounted) {
        setState(() {
          _currentChallenge = first;
          _loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _loading = false);
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
    
    // Pour l'instant, on envoie is_resolved à false car on ne sait pas si c'est la bonne réponse
    // Le backend devrait vérifier et retourner si c'est résolu ou non
    final res = await ApiService.answerChallenge(
      gameSessionId: widget.gameSessionId,
      challengeId: cid,
      answer: _answerCtrl.text.trim(),
      isResolved: false,
    );
    
    setState(() => _submitting = false);

    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Réponse envoyée'), backgroundColor: Colors.green[600]),
      );
      _answerCtrl.clear();
      // Recharger la liste pour récupérer éventuellement un autre challenge à deviner
      await _loadChallengesToGuess();
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
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'En attente de votre dessinateur…',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                        textAlign: TextAlign.center,
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
                                const Text('Image à deviner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
