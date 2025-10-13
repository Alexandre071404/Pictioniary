import 'dart:convert';
import 'package:http/http.dart' as http;
import 'global_data.dart';

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
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $_jwt',
          'Content-Type': 'application/json',
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
      final response = await http.post(
        Uri.parse('$baseUrl/game_sessions'),
        headers: {
          'Authorization': 'Bearer $_jwt',
          'Content-Type': 'application/json',
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
    // Dans api_service.dart, après createGameSession()

static Future<Map<String, dynamic>> joinGameSession(String gameSessionId, String color) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/game_sessions/$gameSessionId/join'),
      headers: {
        'Authorization': 'Bearer $_jwt',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'color': color}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {'success': false, 'error': 'Erreur lors de la jointure à la partie'};
    }
  } catch (_) {
    return {'success': false, 'error': 'Erreur de connexion'};
  }
}

static Future<Map<String, dynamic>> getGameSession(String gameSessionId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/game_sessions/$gameSessionId'),
      headers: {
        'Authorization': 'Bearer $_jwt',
        'Content-Type': 'application/json',
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
    final response = await http.get(
      Uri.parse('$baseUrl/game_sessions/$gameSessionId/status'),
      headers: {
        'Authorization': 'Bearer $_jwt',
        'Content-Type': 'application/json',
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
  
}
