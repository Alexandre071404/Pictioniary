import 'package:flutter/material.dart';
import '../data/api_service.dart';

class ChallengeSubmissionScreen extends StatefulWidget {
  final String gameSessionId;
  final Map<String, dynamic> playerData;

  const ChallengeSubmissionScreen({
    super.key,
    required this.gameSessionId,
    required this.playerData,
  });

  @override
  State<ChallengeSubmissionScreen> createState() => _ChallengeSubmissionScreenState();
}

class _ChallengeSubmissionScreenState extends State<ChallengeSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  // Sélecteurs et inputs selon la consigne
  String _article1 = 'un'; // 'un' | 'une'
  String _preposition = 'sur'; // 'sur' | 'dans'
  String _article2 = 'un'; // 'un' | 'une'
  final _noun1 = TextEditingController();
  final _noun2 = TextEditingController();
  final _f1 = TextEditingController();
  final _f2 = TextEditingController();
  final _f3 = TextEditingController();

  bool _submitting = false;
  int _submittedCount = 0;
  final int _required = 3; // ajusté: 3 challenges par joueur

  @override
  void initState() {
    super.initState();
    _loadMyChallengesCount();
  }

  Future<void> _loadMyChallengesCount() async {
    final res = await ApiService.getMyChallenges(widget.gameSessionId);
    if (res['success'] == true) {
      final data = res['data'];
      int count = 0;
      if (data is List) {
        count = data.length;
      } else if (data is Map && data['items'] is List) {
        count = (data['items'] as List).length;
      }
      setState(() => _submittedCount = count);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final forbidden = [_f1.text, _f2.text, _f3.text]
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (forbidden.length != 3) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Renseignez 3 mots interdits'), backgroundColor: Colors.red[600]),
        );
        return;
      }

      final res = await ApiService.sendChallenge(
        gameSessionId: widget.gameSessionId,
        firstWord: _article1.toLowerCase().trim(),
        secondWord: _noun1.text.trim().toLowerCase(),
        thirdWord: _preposition.toLowerCase().trim(),
        fourthWord: _article2.toLowerCase().trim(),
        fifthWord: _noun2.text.trim().toLowerCase(),
        forbiddenWords: forbidden,
      );

      if (res['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Challenge envoyé !'), backgroundColor: Colors.green[600]),
        );
        setState(() {
          _submittedCount += 1;
          _article1 = 'un';
          _preposition = 'sur';
          _article2 = 'un';
          _noun1.clear();
          _noun2.clear();
          _f1.clear();
          _f2.clear();
          _f3.clear();
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? 'Erreur lors de l\'envoi'), backgroundColor: Colors.red[600]),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_required - _submittedCount).clamp(0, _required);
    final canSubmitMore = remaining > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rédaction des challenges'),
        backgroundColor: const Color(0xFF667EEA),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyChallengesCount,
          )
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Challenges envoyés: $_submittedCount / $_required',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          canSubmitMore
                              ? 'Il vous reste $remaining challenge(s) à soumettre.'
                              : 'Merci ! En attente des autres joueurs…',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (canSubmitMore)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Ligne 1 : "Un/Une" [input]
                            Row(
                              children: [
                                DropdownButton<String>(
                                  value: _article1,
                                  items: const [
                                    DropdownMenuItem(value: 'un', child: Text('Un')),
                                    DropdownMenuItem(value: 'une', child: Text('Une')),
                                  ],
                                  onChanged: (v) => setState(() => _article1 = v ?? 'un'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _noun1,
                                    decoration: const InputDecoration(labelText: 'Objet (ex: poule)'),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Ligne 2 : "Sur/Dans Un/Une" [input]
                            Row(
                              children: [
                                DropdownButton<String>(
                                  value: _preposition,
                                  items: const [
                                    DropdownMenuItem(value: 'sur', child: Text('Sur')),
                                    DropdownMenuItem(value: 'dans', child: Text('Dans')),
                                  ],
                                  onChanged: (v) => setState(() => _preposition = v ?? 'sur'),
                                ),
                                const SizedBox(width: 12),
                                DropdownButton<String>(
                                  value: _article2,
                                  items: const [
                                    DropdownMenuItem(value: 'un', child: Text('Un')),
                                    DropdownMenuItem(value: 'une', child: Text('Une')),
                                  ],
                                  onChanged: (v) => setState(() => _article2 = v ?? 'un'),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _noun2,
                                    decoration: const InputDecoration(labelText: 'Lieu (ex: mur)'),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _f1,
                                    decoration: const InputDecoration(labelText: 'Mot interdit 1'),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _f2,
                                    decoration: const InputDecoration(labelText: 'Mot interdit 2'),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _f3,
                                    decoration: const InputDecoration(labelText: 'Mot interdit 3'),
                                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _submitting ? null : _submit,
                                icon: _submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.send),
                                label: const Text('Envoyer le challenge'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


