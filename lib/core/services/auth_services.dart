import 'dart:convert';
import 'dart:developer';
import 'package:bbd_limited/models/user.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AuthService {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend
  final storage = FlutterSecureStorage();
  static const String _usernameKey = 'username';
  static const String _tokenKey = 'jwt';

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/auth'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      log(response.body);

      if (response.statusCode == 200) {
        final token = response.body;
        await storage.write(key: _tokenKey, value: token);
        await storage.write(key: _usernameKey, value: username);
        return true;
      } else if ((response.statusCode == 401 || response.statusCode == 403) &&
          response.body == "Votre compte est suspendu pour le moment.") {
        throw Exception(
            "Votre compte a été désactivé. Veuillez contacter votre supérieur pour connaître la cause.");
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
            "Identifiants incorrects. Veuillez vérifier votre nom d'utilisateur et mot de passe.");
      } else if (response.statusCode == 404) {
        throw Exception(
            "Utilisateur non trouvé. Veuillez vérifier vos infromations de connexion.");
      } else {
        return false;
      }
    } catch (e) {
      // Si c'est déjà une Exception avec un message personnalisé, on la relance
      if (e is Exception) {
        rethrow;
      }
      // Pour les autres erreurs (réseau, etc.), on retourne false
      return false;
    }
  }

  Future<String?> getToken() async {
    return await storage.read(key: "jwt");
  }

  Future<String?> logout() async {
    await storage.delete(key: "jwt");
    await storage.delete(key: _usernameKey);
    return null;
  }

  Future<String?> getUsername() async {
    return await storage.read(key: _usernameKey);
  }

  Future<User?> getUserInfo() async {
    try {
      final username = await getUsername();
      if (username == null) return null;

      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/users/$username'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(utf8.decode(response.bodyBytes));
        // print('Données utilisateur reçues: $userData');
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des informations utilisateur: $e');
      return null;
    }
  }

  static const String success = "SUCCESS";
  static const String emailExist = "EMAIL_EXIST";
  static const String usernameExist = "USERNAME_EXIST";
  static const String phoneExist = "PHONE_EXIST";
  static const String roleNotFound = "ROLE_NOT_FOUND";

  Future<String> createUser(User userDto) async {
    final url = Uri.parse('$baseUrl/users/create');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userDto.toJson()),
      );

      log(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.body;
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create user');
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors or other exceptions
      throw Exception('Error creating user: $e');
    }
  }

  Future<List<User>> getAllUsers({int page = 0}) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await http.get(
        Uri.parse('$baseUrl/users?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> jsonBody = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonBody.map((e) => User.fromJson(e)).toList();
      } else {
        throw Exception('Erreur lors du chargement des utilisateurs');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<bool> updateUser(int id, User user) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await http.put(
        Uri.parse('$baseUrl/users/update/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Erreur lors de la mise à jour de l\'utilisateur');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<bool> deleteUser(int userIdToDelete, User currentUser) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await http.delete(
        Uri.parse(
          '$baseUrl/users/delete?deleteUser=$userIdToDelete&admin=${currentUser.id}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Si l'utilisateur supprime son propre compte, le déconnecter
        if (currentUser.id == userIdToDelete) {
          await logout();
          Navigator.pushReplacementNamed(
            navigatorKey.currentContext!,
            '/login',
          );
        }
        return true;
      } else {
        // Récupérer le message d'erreur du backend
        final errorMessage = json.decode(response.body)['message'] ??
            'Erreur lors de la suppression de l\'utilisateur';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  Future<void> sendDeleteConfirmationEmail(
    String email,
    String firstName,
    String lastName,
    String username,
  ) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await http.post(
        Uri.parse('$baseUrl/users/send-delete-confirmation'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'editedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de l\'envoi de l\'email de confirmation');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'email: $e');
    }
  }

  String getResponseMessage(String responseCode) {
    switch (responseCode) {
      case success:
        return 'User created successfully';
      case emailExist:
        return 'Email already exists';
      case usernameExist:
        return 'Username already exists';
      case phoneExist:
        return 'Phone number already exists';
      case roleNotFound:
        return 'Specified role not found';
      default:
        return 'Unknown response from server';
    }
  }

  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');

      final user = await getUserInfo();
      if (user == null) throw Exception('Utilisateur non trouvé');

      final response = await http.put(
        Uri.parse('$baseUrl/users/change-password/${user.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'editedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.body;
      } else if (response.statusCode == 400 ||
          response.statusCode == 409 &&
              response.body == "OLD_PASSWORD_INCORRECT") {
        throw Exception('Ancien mot de passe incorrect');
      } else {
        throw Exception('Erreur lors du changement de mot de passe');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<String> disableUser(int userId) async {
    try {
      // Récupérer l'utilisateur courant pour obtenir son ID
      final currentUser = await getUserInfo();
      if (currentUser == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/users/disable/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id':
              currentUser.id.toString(), // 👈 Utilisation du header X-User-Id
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return 'SUCCESS';
        } else {
          return responseData['message'] ?? 'Erreur lors de la désactivation';
        }
      } else if (response.statusCode == 404) {
        return 'USER_NOT_FOUND';
      } else if (response.statusCode == 403) {
        return 'PERMISSION_DENIED';
      } else if (response.statusCode == 400) {
        return 'INVALID_INPUT';
      } else {
        return 'SERVER_ERROR';
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
