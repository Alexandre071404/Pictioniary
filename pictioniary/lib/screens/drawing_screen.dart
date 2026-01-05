import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../data/global_data.dart';

class DrawingScreen extends StatefulWidget {
  final String gameSessionId;
  final Map<String, dynamic> playerData;

  const DrawingScreen({
    super.key,
    required this.gameSessionId,
    required this.playerData,
  });

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  Map<String, dynamic>? _currentChallenge;
  bool _loading = true;
  bool _submitting = false;
  final _promptCtrl = TextEditingController();
  static const int _maxRegenerations = 2;
  int _regenerationsUsed = 0;
  List<String> _previousImages = [];
  String? _currentImageUrl;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _loadMyChallenges();
    _startStatusPolling();
  }

  Future<void> _loadMyChallenges() async {
    setState(() => _loading = true);
    final res = await ApiService.getMyChallenges(widget.gameSessionId);
    if (res['success'] == true) {
      final data = res['data'];
      Map<String, dynamic>? selected;
      List<dynamic> list = [];
      if (data is List && data.isNotEmpty) {
        list = data;
      } else if (data is Map && data['items'] is List && (data['items'] as List).isNotEmpty) {
        list = data['items'] as List;
      }
      // Sélectionner en priorité un challenge SANS image (prochain à dessiner)
      for (final raw in list) {
        if (raw is Map) {
          final m = Map<String, dynamic>.from(raw as Map);
          final hasImage = (m['image_path'] ?? m['imageUrl']) != null &&
              (m['image_path'] ?? m['imageUrl']).toString().isNotEmpty;
          final hasPrev = _extractPreviousImages(m).isNotEmpty;
          if (!hasImage && !hasPrev) {
            selected = m;
            break;
          }
        }
      }
      // S'il n'y a plus de challenge sans image, on ne sélectionne rien :
      // le joueur n'a plus rien à dessiner et attend que la phase passe à "guessing".

      final List<String> prevImages = selected != null ? _extractPreviousImages(selected) : [];
      final String? imgUrl = selected != null ? _resolveImageUrl(selected['image_path'] ?? selected['imageUrl']) : null;
      setState(() {
        _currentChallenge = selected;
        _previousImages = prevImages;
        _currentImageUrl = imgUrl;
        _regenerationsUsed = _calculateRegenerationsUsed(prevImages);
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _submitPrompt() async {
    if (_currentChallenge == null) return;
    if (_promptCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Écris un prompt'), backgroundColor: Colors.red[600]),
      );
      return;
    }
    setState(() => _submitting = true);
    final cid = (_currentChallenge!['id'] ?? _currentChallenge!['_id'] ?? _currentChallenge!['challengeId']).toString();
    final res = await ApiService.submitDrawForChallenge(
      gameSessionId: widget.gameSessionId,
      challengeId: cid,
      prompt: _promptCtrl.text.trim(),
    );
    setState(() => _submitting = false);
    if (res['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_currentImageUrl == null ? 'Image générée !' : 'Nouvelle génération envoyée (-10 pts)'),
          backgroundColor: Colors.green[600],
        ),
      );
      if (res['data'] is Map) {
        final Map<String, dynamic> updated = Map<String, dynamic>.from(res['data'] as Map);
        final updatedPrev = _extractPreviousImages(updated);
        final updatedImage = _resolveImageUrl(updated['image_path'] ?? updated['imageUrl']);
        setState(() {
          _currentChallenge = updated;
          _previousImages = updatedPrev;
          _currentImageUrl = updatedImage;
          _regenerationsUsed = _calculateRegenerationsUsed(updatedPrev);
        });
      }
      _promptCtrl.clear();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['error'] ?? 'Erreur lors de l\'envoi'), backgroundColor: Colors.red[600]),
      );
    }
  }

  Future<void> _confirmGeneration() async {
    if (_currentChallenge == null) return;
    if (_currentImageUrl == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Génère une image avant de valider'), backgroundColor: Colors.orange[600]),
      );
      return;
    }
    setState(() => _loading = true);
    await _loadMyChallenges();
    if (!mounted) return;
    // Passage au prochain challenge (ou écran vide s'il n'y en a plus) :
    // on réinitialise systématiquement l'état de génération local.
    setState(() {
      _currentImageUrl = null;
      _previousImages = [];
      _regenerationsUsed = 0;
    });
    _promptCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Génération validée, prochain challenge !'), backgroundColor: Colors.green[600]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase Dessin'),
        backgroundColor: const Color(0xFF667EEA),
        actions: [
          IconButton(onPressed: _loadMyChallenges, icon: const Icon(Icons.refresh))
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
                    child: Text('Aucun challenge à dessiner pour le moment', style: TextStyle(color: Colors.white70)),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Challenge reçu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(
                                  _formatChallengeSentence(_currentChallenge!),
                                  style: const TextStyle(color: Colors.white, fontSize: 18),
                                ),
                                const SizedBox(height: 12),
                                const Text('Mots interdits', style: TextStyle(color: Colors.white70)),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: _extractForbiddenWords(_currentChallenge!).isNotEmpty
                                      ? _extractForbiddenWords(_currentChallenge!).map((word) {
                                          return Chip(
                                            label: Text(word),
                                            backgroundColor: Colors.red.withOpacity(0.2),
                                            labelStyle: const TextStyle(color: Colors.white),
                                          );
                                        }).toList()
                                      : [
                                          const Text('Aucun mot interdit fourni', style: TextStyle(color: Colors.white54)),
                                        ],
                                ),
                                if (_currentImageUrl != null) ...[
                                  const SizedBox(height: 16),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _currentImageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 220,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return SizedBox(
                                          height: 220,
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
                                        height: 220,
                                        color: Colors.black26,
                                        child: const Center(
                                          child: Text('Impossible de charger l’image', style: TextStyle(color: Colors.white70)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Régénérations restantes : ${(_maxRegenerations - _regenerationsUsed).clamp(0, _maxRegenerations)}',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                                if (_previousImages.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text('Images précédentes', style: TextStyle(color: Colors.white70)),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (context, index) {
                                        final url = _previousImages[index];
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            url,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              width: 100,
                                              height: 100,
                                              color: Colors.black26,
                                              child: const Icon(Icons.broken_image, color: Colors.white54),
                                            ),
                                          ),
                                        );
                                      },
                                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                                      itemCount: _previousImages.length,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _promptCtrl,
                            maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Prompt (sans les mots du challenge ni les interdits)',
                            hintText: 'Décrivez l\'image à générer…',
                          ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: (_submitting || _isRegenerationLimitReached) ? null : _submitPrompt,
                                  icon: _submitting
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : Icon(_currentImageUrl == null ? Icons.image : Icons.refresh),
                                  label: Text(_currentImageUrl == null
                                      ? 'Générer'
                                      : _isRegenerationLimitReached
                                          ? 'Limite atteinte'
                                          : 'Régénérer (-10 pts)'),
                                ),
                              ),
                              if (_currentImageUrl != null) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: (_loading || _currentChallenge == null) ? null : _confirmGeneration,
                                    icon: const Icon(Icons.check_circle_outline),
                                    label: const Text('Valider ma génération'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
      ),
    );
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) {
        _statusTimer?.cancel();
        return;
      }
      await _checkStatusAndMaybeNavigate();
    });
  }

  Future<void> _checkStatusAndMaybeNavigate() async {
    // Tant qu'il reste un challenge courant à dessiner, on reste sur cet écran.
    if (_currentChallenge != null) return;

    final statusRes = await ApiService.getGameSessionStatus(widget.gameSessionId);
    if (statusRes['success'] == true) {
      final s = statusRes['data']['status'];
      if (s == 'guessing') {
        _statusTimer?.cancel();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          '/guessing_wait',
          arguments: {
            'gameSessionId': widget.gameSessionId,
            'playerData': widget.playerData,
          },
        );
      }
    }
  }

  String _formatChallengeSentence(Map<String, dynamic> challenge) {
    final fw = _readWord(challenge, 'first');
    final sw = _readWord(challenge, 'second');
    final tw = _readWord(challenge, 'third');
    final fw2 = _readWord(challenge, 'fourth');
    final fifth = _readWord(challenge, 'fifth');
    return [fw, sw, tw, fw2, fifth].where((p) => p.isNotEmpty).join(' ');
  }

  String _readWord(Map<String, dynamic> challenge, String position) {
    final snake = '${position}_word';
    final camel = '${position}Word';
    return (challenge[snake] ?? challenge[camel] ?? '').toString();
  }

  List<String> _extractForbiddenWords(Map<String, dynamic> challenge) {
    final raw = challenge['forbidden_words'] ?? challenge['forbiddenWords'] ?? challenge['forbidden'] ?? [];
    List<dynamic> listDynamic = [];
    if (raw is List) {
      listDynamic = raw;
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          listDynamic = decoded;
        } else if (decoded is String) {
          listDynamic = decoded.split(',');
        }
      } catch (_) {
        listDynamic = raw
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',')
            .map((e) => e.replaceAll('"', '').replaceAll("'", '').trim())
            .toList();
      }
    }
    if (listDynamic.isNotEmpty) {
      return listDynamic.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return [];
  }

  List<String> _extractPreviousImages(Map<String, dynamic> challenge) {
    final raw = challenge['previous_images'] ?? challenge['previousImages'] ?? [];
    List<dynamic> listDynamic = [];
    if (raw is List) {
      listDynamic = raw;
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          listDynamic = decoded;
        }
      } catch (_) {
        listDynamic = raw
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',')
            .map((e) => e.replaceAll('"', '').replaceAll("'", '').trim())
            .toList();
      }
    }
    if (listDynamic.isNotEmpty) {
      return listDynamic
          .map((e) => _resolveImageUrl(e))
          .whereType<String>()
          .toList();
    }
    return [];
  }

  int _calculateRegenerationsUsed(List<String> prevImages) {
    if (prevImages.isEmpty) return 0;
    final regenCount = prevImages.length - 1;
    return regenCount.clamp(0, _maxRegenerations);
  }

  bool get _isRegenerationLimitReached => _currentImageUrl != null && _regenerationsUsed >= _maxRegenerations;

  String? _resolveImageUrl(dynamic raw) {
    if (raw == null) return null;
    final path = raw.toString();
    if (path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    final sanitizedBase = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$sanitizedBase$normalizedPath';
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _promptCtrl.dispose();
    super.dispose();
  }
}

