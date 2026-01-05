import 'package:flutter/material.dart';

class DocsScreen extends StatelessWidget {
  const DocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentation Technique'),
        backgroundColor: const Color(0xFF667EEA),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF111827)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                '📱 Application Piction.ia.ry',
                'Application mobile de jeu de dessin et de devinette en équipe.',
                [
                  _buildSubsection('Description', 'Jeu multijoueur où les joueurs créent des challenges, génèrent des images avec IA, et tentent de deviner les images des autres équipes.'),
                  _buildSubsection('Technologies', 'Flutter, Dart, REST API'),
                ],
              ),
              const SizedBox(height: 32),
              _buildSection(
                '🎮 Fonctionnalités',
                'Liste des fonctionnalités principales de l\'application.',
                [
                  _buildSubsection('Authentification', 'Création de compte et connexion des joueurs'),
                  _buildSubsection('Création de partie', 'Création et gestion de sessions de jeu'),
                  _buildSubsection('Système d\'équipes', 'Rejoindre une équipe (Rouge ou Bleue)'),
                  _buildSubsection('QR Code', 'Génération et scan de QR codes pour rejoindre une partie'),
                  _buildSubsection('Création de challenges', 'Création de 3 challenges par joueur avec mots interdits'),
                  _buildSubsection('Génération d\'images', 'Génération d\'images avec IA (StableDiffusion) basée sur les prompts'),
                  _buildSubsection('Régénération', 'Possibilité de régénérer une image (max 2 fois, -10 points par régénération)'),
                  _buildSubsection('Phase de devinette', 'Tentative de deviner les images générées par les autres équipes'),
                  _buildSubsection('Calcul des scores', 'Système de points basé sur les challenges résolus et les pénalités'),
                  _buildSubsection('Résultats', 'Affichage détaillé des résultats de la partie'),
                ],
              ),
              const SizedBox(height: 32),
              _buildSection(
                '🏗️ Architecture',
                'Structure technique de l\'application.',
                [
                  _buildSubsection('Écrans principaux', 
                    '• MenuScreen: Menu principal\n'
                    '• LoginScreen: Connexion/Création de compte\n'
                    '• LobbyScreen: Lobby de la partie\n'
                    '• JoinGameScreen: Rejoindre une partie\n'
                    '• ChallengeSubmissionScreen: Création de challenges\n'
                    '• DrawingScreen: Génération d\'images\n'
                    '• GuessingWaitScreen: Phase de devinette\n'
                    '• ResultsScreen: Résultats finaux\n'
                    '• ScanQRScreen: Scanner un QR code'),
                  _buildSubsection('Services', 
                    '• ApiService: Gestion de toutes les requêtes API\n'
                    '• GlobalData: Configuration (baseUrl)'),
                  _buildSubsection('État de l\'application', 
                    'Gestion d\'état avec StatefulWidget et setState'),
                ],
              ),
              const SizedBox(height: 32),
              _buildSection(
                '🔌 API',
                'Endpoints et méthodes de l\'API backend.',
                [
                  _buildSubsection('Base URL', 'https://pictioniary.wevox.cloud/api'),
                  _buildSubsection('Authentification', 
                    '• POST /players - Créer un joueur\n'
                    '• POST /auth/login - Se connecter\n'
                    '• GET /auth/me - Obtenir les infos du joueur'),
                  _buildSubsection('Sessions de jeu', 
                    '• POST /game_sessions - Créer une session\n'
                    '• GET /game_sessions/{id} - Obtenir une session\n'
                    '• GET /game_sessions/{id}/status - Obtenir le statut\n'
                    '• POST /game_sessions/{id}/join - Rejoindre une équipe\n'
                    '• POST /game_sessions/{id}/start - Démarrer la partie\n'
                    '• POST /game_sessions/{id}/leave - Quitter la partie'),
                  _buildSubsection('Challenges', 
                    '• POST /game_sessions/{id}/challenges - Créer un challenge\n'
                    '• GET /game_sessions/{id}/challenges/my - Mes challenges\n'
                    '• GET /game_sessions/{id}/challenges/to-guess - Challenges à deviner\n'
                    '• GET /game_sessions/{id}/challenges/all - Tous les challenges\n'
                    '• POST /game_sessions/{id}/challenges/{challengeId}/draw - Générer une image\n'
                    '• POST /game_sessions/{id}/challenges/{challengeId}/answer - Répondre à un challenge'),
                ],
              ),
              const SizedBox(height: 32),
              _buildSection(
                '📊 Système de scores',
                'Règles de calcul des points.',
                [
                  _buildSubsection('Points de base', 'Chaque équipe commence avec 100 points'),
                  _buildSubsection('Gains', 
                    '• +25 points par mot trouvé dans un challenge résolu\n'
                    '• Un challenge est résolu si la réponse correspond exactement (normalisée)'),
                  _buildSubsection('Pertes', 
                    '• -10 points par régénération d\'image (max 2 régénérations)\n'
                    '• -1 point par mauvaise réponse'),
                ],
              ),
              const SizedBox(height: 32),
              _buildSection(
                '🔄 Flux de jeu',
                'Déroulement d\'une partie.',
                [
                  _buildSubsection('1. Lobby', 'Les joueurs rejoignent une équipe (Rouge ou Bleue)'),
                  _buildSubsection('2. Challenge', 'Chaque joueur crée 3 challenges avec 5 mots et des mots interdits'),
                  _buildSubsection('3. Drawing', 'Les joueurs génèrent des images pour leurs challenges'),
                  _buildSubsection('4. Guessing', 'Les joueurs tentent de deviner les images des autres équipes'),
                  _buildSubsection('5. Results', 'Affichage des résultats et des scores finaux'),
                ],
              ),
              const SizedBox(height: 32),
              _buildSection(
                '📦 Packages utilisés',
                'Dépendances principales de l\'application.',
                [
                  _buildSubsection('Core', 
                    '• flutter: SDK Flutter\n'
                    '• http: ^0.13.6 - Requêtes HTTP\n'
                    '• flutter_riverpod: ^3.0.0 - Gestion d\'état'),
                  _buildSubsection('QR Code', 
                    '• qr_code_scanner_plus: ^2.0.14 - Scanner de QR codes\n'
                    '• qr_flutter: ^4.1.0 - Génération de QR codes'),
                ],
              ),
              const SizedBox(height: 32),
              _buildSection(
                '🔐 Sécurité',
                'Mesures de sécurité implémentées.',
                [
                  _buildSubsection('Authentification', 'Utilisation de JWT (JSON Web Tokens) pour l\'authentification'),
                  _buildSubsection('Headers', 'Tous les appels API incluent le token JWT dans les headers Authorization'),
                  _buildSubsection('Validation', 'Validation des données côté client et serveur'),
                ],
              ),
              const SizedBox(height: 32),
              _buildSection(
                '🎨 UI/UX',
                'Design et expérience utilisateur.',
                [
                  _buildSubsection('Thème', 'Thème sombre avec dégradés (0xFF0F172A à 0xFF111827)'),
                  _buildSubsection('Couleurs principales', 
                    '• Primaire: #667EEA\n'
                    '• Rouge: Pour l\'équipe rouge\n'
                    '• Bleu: Pour l\'équipe bleue\n'
                    '• Vert: Pour les succès\n'
                    '• Rouge: Pour les erreurs'),
                  _buildSubsection('Vouvoiement', 'Interface utilisant le vouvoiement pour un ton formel'),
                ],
              ),
              const SizedBox(height: 32),
              _buildSection(
                '🐛 Gestion des erreurs',
                'Stratégies de gestion des erreurs.',
                [
                  _buildSubsection('Réseau', 'Gestion des erreurs de connexion avec messages utilisateur'),
                  _buildSubsection('API', 'Affichage des messages d\'erreur retournés par l\'API'),
                  _buildSubsection('État', 'Vérification de mounted avant setState pour éviter les erreurs'),
                  _buildSubsection('Polling', 'Système de polling avec Timer pour mettre à jour l\'état'),
                ],
              ),
              const SizedBox(height: 32),
              _buildSection(
                '📝 Notes techniques',
                'Informations importantes pour les développeurs.',
                [
                  _buildSubsection('Normalisation de texte', 
                    'Les réponses sont normalisées (minuscules, sans accents, sans ponctuation) pour la comparaison'),
                  _buildSubsection('Polling', 
                    'Utilisation de Timer.periodic pour vérifier régulièrement le statut de la partie'),
                  _buildSubsection('Navigation', 
                    'Navigation automatique entre les écrans selon le statut de la partie'),
                  _buildSubsection('Images', 
                    'Les images générées sont stockées sur le serveur et affichées via URL'),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String description, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildSubsection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

