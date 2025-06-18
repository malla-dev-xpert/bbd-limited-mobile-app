import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:bbd_limited/models/embarquement.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PackageServices {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  Future<List<Packages>> findAll({int page = 0, String? query}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/packages?page=$page&query=${query ?? ''}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
      return jsonBody.map((e) => Packages.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des expeditions");
    }
  }

  Future<String?> create({
    required Packages dto,
    required int clientId,
    required int userId,
    int? containerId,
    required int warehouseId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/packages/create?clientId=$clientId&userId=$userId&containerId=$containerId&warehouseId=$warehouseId',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dto.toJson()),
      );

      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "SUCCESS";
      }
    } on http.ClientException catch (e) {
      return 'NETWORK_ERROR';
    } catch (e) {
      throw Exception('Erreur inattendue: ${e.toString()}');
    }
  }

  Future<String?> startExpedition(int id) async {
    final url = Uri.parse(
      "$baseUrl/packages/start-expedition?expeditionId=$id",
    );

    try {
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "SUCCESS";
      } else {
        return "Erreur : ${response.body}";
      }
    } catch (e) {
      return "Erreur lors du démarrage de l'expédition : $e";
    }
  }

  Future<String?> deliverExpedition(int id) async {
    final url = Uri.parse(
      "$baseUrl/packages/deliver-expedition?expeditionId=$id",
    );

    try {
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "SUCCESS";
      } else {
        return "Erreur : ${response.body}";
      }
    } catch (e) {
      return "Erreur lors de la livraison de l'expédition : $e";
    }
  }

  Future<String?> receivedExpedition(int id) async {
    final url = Uri.parse(
      "$baseUrl/packages/received-expedition?expeditionId=$id",
    );

    try {
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "SUCCESS";
      } else {
        return "Erreur : ${response.body}";
      }
    } catch (e) {
      return "Erreur lors de la livraison de l'expédition : $e";
    }
  }

  Future<String?> deleteExpedition(int id) async {
    final url = Uri.parse("$baseUrl/packages/delete?expeditionId=$id");

    try {
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "SUCCESS";
      } else {
        return "Erreur : ${response.body}";
      }
    } catch (e) {
      return "Erreur lors de la suppression de l'expédition : $e";
    }
  }

  Future<String?> updateExpedition(
    int id,
    Packages expeditionDto,
    int userId,
  ) async {
    final url = Uri.parse('$baseUrl/packages/update/$id?userId=$userId');
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(expeditionDto.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "SUCCESS";
      } else {
        return "Erreur : ${response.body}";
      }
    } catch (e) {
      return "Erreur lors de la mise à jour de l'expédition : $e";
    }
  }

  Future<List<Packages>> findByWarehouse(int warehouseId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/packages/warehouse?warehouseId=$warehouseId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
      return jsonBody.map((e) => Packages.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des colis");
    }
  }

  // Future<List<Packages>> findAll({int page = 0}) async {
  //   final response = await http.get(Uri.parse('$baseUrl/packages?page=$page'));

  //   if (response.statusCode == 200) {
  //     final List<dynamic> jsonBody = json.decode(
  //       utf8.decode(response.bodyBytes),
  //     );
  //     return jsonBody.map((e) => Packages.fromJson(e)).toList();
  //   } else {
  //     throw Exception("Erreur lors du chargement des colis");
  //   }
  // }

  Future<List<Packages>> findAllPackageReceived({int page = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/packages/received?page=$page'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
      return jsonBody.map((e) => Packages.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des colis");
    }
  }

  Future<String?> removePackageFromContainer({
    required int packageId,
    required int containerId,
    required int userId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/packages/$packageId/container/$containerId?userId=$userId',
    );

    try {
      final response = await http.delete(url);

      switch (response.statusCode) {
        case 200 || 201:
          return "REMOVED";
        case 400 || 409:
          final errorMsg = response.body;
          if (errorMsg.contains("CONTAINER_INPROGRESS")) {
            return "CONTAINER_INPROGRESS";
          } else if (errorMsg.contains("PACKAGE_NOT_IN_CONTAINER")) {
            return "PACKAGE_NOT_IN_CONTAINER";
          }
          return "UNKNOWN_ERROR";
        case 404:
          return "NOT_FOUND";
        default:
          return "SERVER_ERROR";
      }
    } catch (e) {
      throw Exception("Erreur réseau: ${e.toString()}");
    }
  }

  Future<String> embarquerColis(EmbarquementRequest request, int userId) async {
    try {
      final url = Uri.parse('$baseUrl/containers/embarquer?userId=$userId');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == HttpStatus.created) {
        return "SUCCESS";
      } else if (response.statusCode == HttpStatus.conflict) {
        final errorMessage = response.body;

        if (errorMessage.contains("Le conteneur n'est pas disponible")) {
          return "CONTAINER_NOT_AVAILABLE";
        } else if (errorMessage.contains("est déjà dans le conteneur")) {
          return "PACKAGE_ALREADY_IN_ANOTHER_CONTAINER";
        } else if (errorMessage.contains("n'est pas en statut PENDING")) {
          return "PACKAGE_NOT_IN_RECEIVED_STATUS";
        }
        return "CONFLICT_ERROR";
      } else if (response.statusCode == HttpStatus.notFound) {
        return "CONTAINER_NOT_FOUND";
      } else {
        return "SERVER_ERROR: ${response.statusCode}";
      }
    } on SocketException {
      return "NETWORK_ERROR";
    } on TimeoutException {
      return "TIMEOUT_ERROR";
    } on FormatException {
      return "FORMAT_ERROR";
    } catch (e) {
      return "UNEXPECTED_ERROR: ${e.toString()}";
    }
  }

  // Future<void> addItemsToPackage(
  //   int packageId,
  //   List<Map<String, dynamic>> items,
  //   int userId,
  // ) async {
  //   final url = Uri.parse(
  //     '$baseUrl/packages/$packageId/add-items?userId=$userId',
  //   );

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: json.encode(items),
  //     );

  //     if (response.statusCode != 200) {
  //       throw Exception('Failed to add items to package');
  //     }
  //   } catch (e) {
  //     throw Exception('Error adding items to package: $e');
  //   }
  // }

  // Future<bool> updatePackage(int id, int? userId, Packages dto) async {
  //   try {
  //     final url = Uri.parse('$baseUrl/packages/update/$id?userId=$userId');
  //     final headers = {'Content-Type': 'application/json'};

  //     final response = await http.put(
  //       url,
  //       headers: headers,
  //       body: jsonEncode(dto.toJson()),
  //     );

  //     if (response.statusCode == 409 &&
  //         response.body == 'Nom de colis déjà utilisé !') {
  //       return false;
  //     }

  //     if (response.statusCode == 201) {
  //       return true;
  //     } else {
  //       final errorData = jsonDecode(response.body);
  //       throw Exception(errorData['message'] ?? 'Échec de la mise à jour');
  //     }
  //   } catch (e) {
  //     rethrow;
  //   }
  // }
}
