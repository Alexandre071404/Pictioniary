import 'dart:convert';
import 'package:http/http.dart' as http;
import 'global_data.dart';
import 'dart:developer' as developer; // Ajout de l'importation manquante

class ApiService {
  static String? _jwt;

  static Future<Map<String, dynamic>> createPlayer(String name, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/players'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Erreur lors de la création du compte'};
      }
    } catch (_) {
      return {'success': false, 'error': 'Erreur de connexion'};
    }
  }

  static Future<Map<String, dynamic>> login(String name, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _jwt = data['jwt'] ?? data['token'] ?? data['access_token'];
        developer.log('Login OK, jwt set length: ${_jwt?.length}', name: 'ApiService');
        return {'success': true, 'jwt': _jwt};
      } else {
        return {'success': false, 'error': 'Nom d\'utilisateur ou mot de passe incorrect'};
      }
    } catch (_) {
      return {'success': false, 'error': 'Erreur de connexion'};
    }
  }

  static Future<Map<String, dynamic>> getMe() async {
    try {
      developer.log('GET /me with JWT? ${_jwt != null}', name: 'ApiService');
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $_jwt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Erreur lors de la récupération du profil'};
      }
    } catch (_) {
      return {'success': false, 'error': 'Erreur de connexion'};
    }
  }

  static Future<Map<String, dynamic>> createGameSession() async {
    try {
      developer.log('POST /game_sessions', name: 'ApiService');
      final response = await http.post(
        Uri.parse('$baseUrl/game_sessions'),
        headers: {
          'Authorization': 'Bearer $_jwt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Erreur lors de la création de la partie'};
      }
    } catch (_) {
      return {'success': false, 'error': 'Erreur de connexion'};
    }
  }

  static Future<Map<String, dynamic>> joinGameSession(String gameSessionId, String color) async {
    try {
      developer.log('POST /game_sessions/$gameSessionId/join color=$color, JWT? ${_jwt != null}', name: 'ApiService');
      final response = await http.post(
        Uri.parse('$baseUrl/game_sessions/$gameSessionId/join'),
        headers: {
          'Authorization': 'Bearer $_jwt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'color': color}),
      );

      developer.log('Join response: status=${response.statusCode}, body=${response.body}', name: 'ApiService'); // Log ajouté

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        // Parse error du body si possible
        Map<String, dynamic>? errorData;
        try { errorData = jsonDecode(response.body); } catch (_) {}
        return {'success': false, 'error': errorData?['error'] ?? 'Erreur lors de la jointure à la partie (status: ${response.statusCode})'};
      }
    } catch (e) {
      developer.log('Join exception: $e', name: 'ApiService');
      return {'success': false, 'error': 'Erreur de connexion: $e'};
    }
  }

  static Future<Map<String, dynamic>> getGameSession(String gameSessionId) async {
    try {
      developer.log('GET /game_sessions/$gameSessionId', name: 'ApiService');
      final response = await http.get(
        Uri.parse('$baseUrl/game_sessions/$gameSessionId'),
        headers: {
          'Authorization': 'Bearer $_jwt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Erreur lors de la récupération de la partie'};
      }
    } catch (_) {
      return {'success': false, 'error': 'Erreur de connexion'};
    }
  }

  static Future<Map<String, dynamic>> getGameSessionStatus(String gameSessionId) async {
    try {
      developer.log('GET /game_sessions/$gameSessionId/status', name: 'ApiService');
      final response = await http.get(
        Uri.parse('$baseUrl/game_sessions/$gameSessionId/status'),
        headers: {
          'Authorization': 'Bearer $_jwt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Erreur lors de la récupération du statut'};
      }
    } catch (_) {
      return {'success': false, 'error': 'Erreur de connexion'};
    }
  }

  static Future<Map<String, dynamic>> startGameSession(String gameSessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/game_sessions/$gameSessionId/start'),
        headers: {
          'Authorization': 'Bearer $_jwt',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Erreur lors du démarrage de la partie'};
      }
    } catch (_) {
      return {'success': false, 'error': 'Erreur de connexion'};
    }
  }

  static Future<Map<String, dynamic>> leaveGameSession(String gameSessionId) async {
    try {
      developer.log('GET /game_sessions/$gameSessionId/leave', name: 'ApiService');
      final response = await http.get(
        Uri.parse('$baseUrl/game_sessions/$gameSessionId/leave'),
        headers: {
          'Authorization': 'Bearer $_jwt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Erreur lors de la sortie du lobby'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur de connexion: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendChallenge({
    required String gameSessionId,
    required String firstWord,
    required String secondWord,
    required String thirdWord,
    required String fourthWord,
    required String fifthWord,
    required List<String> forbiddenWords,
  }) async {
    try {
      developer.log('POST /game_sessions/$gameSessionId/challenges', name: 'ApiService');
      final response = await http.post(
        Uri.parse('$baseUrl/game_sessions/$gameSessionId/challenges'),
        headers: {
          'Authorization': 'Bearer $_jwt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'first_word': firstWord,
          'second_word': secondWord,
          'third_word': thirdWord,
          'fourth_word': fourthWord,
          'fifth_word': fifthWord,
          'forbidden_words': forbiddenWords,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        Map<String, dynamic>? errorData;
        try { errorData = jsonDecode(response.body); } catch (_) {}
        return {'success': false, 'error': errorData?['error'] ?? 'Erreur lors de l\'envoi du challenge'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur de connexion: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMyChallenges(String gameSessionId) async {
    try {
      developer.log('GET /game_sessions/$gameSessionId/myChallenges', name: 'ApiService');
      final response = await http.get(
        Uri.parse('$baseUrl/game_sessions/$gameSessionId/myChallenges'),
        headers: {
          'Authorization': 'Bearer $_jwt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Erreur lors de la récupération des challenges'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur de connexion: $e'};
    }
  }
}