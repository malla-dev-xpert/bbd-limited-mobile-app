import 'dart:convert';
import 'dart:io';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/embarquement.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ContainerServices {
  final String baseUrl =
      dotenv.env['BASE_URL'] ?? ''; // Récupère l'URL du backend

  Future<List<Containers>> findAll({int page = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/containers?page=$page'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
      return jsonBody.map((e) => Containers.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des conteneurs");
    }
  }

  Future<List<Containers>> findAllContainerNotInHarbor({int page = 0}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/containers/not-in-harbor?page=$page'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonBody = json.decode(
        utf8.decode(response.bodyBytes),
      );
      return jsonBody.map((e) => Containers.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des conteneurs");
    }
  }

  Future<Containers> getContainerDetails(int containerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/containers/$containerId'),
    );

    if (response.statusCode == 200) {
      return Containers.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Erreur lors du chargement du conteneur');
    }
  }

  Future<String?> create(
    String reference,
    String size,
    bool isAvailable,
    int? userId,
    int? supplierId,
    double? locationFee,
    String? locationFeeCurrencyCode,
    double? locationFeeRateToCNY,
    double? localCharge,
    String? localChargeCurrencyCode,
    double? localChargeRateToCNY,
    double? loadingFee,
    String? loadingFeeCurrencyCode,
    double? loadingFeeRateToCNY,
    double? overweightFee,
    String? overweightFeeCurrencyCode,
    double? overweightFeeRateToCNY,
    double? checkingFee,
    String? checkingFeeCurrencyCode,
    double? checkingFeeRateToCNY,
    double? telxFee,
    String? telxFeeCurrencyCode,
    double? telxFeeRateToCNY,
    double? otherFees,
    String? otherFeesCurrencyCode,
    double? otherFeesRateToCNY,
    double? margin,
    String? marginCurrencyCode,
    double? marginRateToCNY,
  ) async {
    try {
      String url = '$baseUrl/containers/create?userId=$userId';
      if (supplierId != null) {
        url += '&supplierId=$supplierId';
      }

      // Construire le body JSON avec seulement les champs non nuls
      final Map<String, dynamic> body = {
        "reference": reference,
        "size": size,
        "isAvailable": isAvailable,
      };

      // Ajouter les frais et leurs devises/taux seulement s'ils ne sont pas null
      if (locationFee != null) {
        body["locationFee"] = locationFee;
        if (locationFeeCurrencyCode != null) {
          body["locationFeeCurrencyCode"] = locationFeeCurrencyCode;
        }
        if (locationFeeRateToCNY != null) {
          body["locationFeeRateToCNY"] = locationFeeRateToCNY;
        }
      }
      if (localCharge != null) {
        body["localCharge"] = localCharge;
        if (localChargeCurrencyCode != null) {
          body["localChargeCurrencyCode"] = localChargeCurrencyCode;
        }
        if (localChargeRateToCNY != null) {
          body["localChargeRateToCNY"] = localChargeRateToCNY;
        }
      }
      if (loadingFee != null) {
        body["loadingFee"] = loadingFee;
        if (loadingFeeCurrencyCode != null) {
          body["loadingFeeCurrencyCode"] = loadingFeeCurrencyCode;
        }
        if (loadingFeeRateToCNY != null) {
          body["loadingFeeRateToCNY"] = loadingFeeRateToCNY;
        }
      }
      if (overweightFee != null) {
        body["overweightFee"] = overweightFee;
        if (overweightFeeCurrencyCode != null) {
          body["overweightFeeCurrencyCode"] = overweightFeeCurrencyCode;
        }
        if (overweightFeeRateToCNY != null) {
          body["overweightFeeRateToCNY"] = overweightFeeRateToCNY;
        }
      }
      if (checkingFee != null) {
        body["checkingFee"] = checkingFee;
        if (checkingFeeCurrencyCode != null) {
          body["checkingFeeCurrencyCode"] = checkingFeeCurrencyCode;
        }
        if (checkingFeeRateToCNY != null) {
          body["checkingFeeRateToCNY"] = checkingFeeRateToCNY;
        }
      }
      if (telxFee != null) {
        body["telxFee"] = telxFee;
        if (telxFeeCurrencyCode != null) {
          body["telxFeeCurrencyCode"] = telxFeeCurrencyCode;
        }
        if (telxFeeRateToCNY != null) {
          body["telxFeeRateToCNY"] = telxFeeRateToCNY;
        }
      }
      if (otherFees != null) {
        body["otherFees"] = otherFees;
        if (otherFeesCurrencyCode != null) {
          body["otherFeesCurrencyCode"] = otherFeesCurrencyCode;
        }
        if (otherFeesRateToCNY != null) {
          body["otherFeesRateToCNY"] = otherFeesRateToCNY;
        }
      }
      if (margin != null) {
        body["margin"] = margin;
        if (marginCurrencyCode != null) {
          body["marginCurrencyCode"] = marginCurrencyCode;
        }
        if (marginRateToCNY != null) {
          body["marginRateToCNY"] = marginRateToCNY;
        }
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("-------------------------------------------");
      print("Response=================" + response.body);
      print("-------------------------------------------");

      if (response.statusCode == 201) {
        return "CREATED";
      } else if (response.statusCode == 409 &&
          response.body == 'Numéro d\'identification déjà utilisé !') {
        return "NAME_EXIST";
      } else {
        throw Exception("Erreur (${response.statusCode}) : ${response.body}");
      }
    } catch (e) {
      throw Exception("Erreur de connexion: $e");
    }
  }

  Future<String?> delete(int id, int? userId) async {
    final url = Uri.parse("$baseUrl/containers/delete/$id?userId=$userId");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 201) {
        return "DELETED";
      } else if (response.statusCode == 409 &&
          response.body == 'Conteneur introuvable.') {
        return "CONTAINER_NOT_FOUND";
      } else if (response.statusCode == 409 &&
          response.body == 'Utilisateur introuvable.') {
        return "USER_NOT_FOUND";
      } else if (response.statusCode == 409 &&
          response.body ==
              'Impossible de supprimer : Des colis existent dans ce conteneur.') {
        return "PACKAGE_EXIST";
      } else {
        throw Exception("Erreur (${response.statusCode}) : ${response.body}");
      }
    } catch (e) {
      throw Exception("Erreur lors de la suppression du conteneur : $e");
    }
  }

  Future<String?> startDelivery(int id, int? userId,
      [DateTime? deliveryDate]) async {
    String urlStr = "$baseUrl/containers/delivery/$id?userId=$userId";
    if (deliveryDate != null) {
      final formattedDate = deliveryDate.toIso8601String();
      urlStr += "&deliveryDate=$formattedDate";
    }
    final url = Uri.parse(urlStr);

    try {
      final response = await http.get(url);

      print("----------------------------------------");
      print(response.body);
      print(response.statusCode);
      print("----------------------------------------");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return "SUCCESS";
      } else if (response.statusCode == 409 &&
          response.body ==
              'Impossible de démarrer la livraison, pas de colis dans le conteneur.') {
        return "NO_PACKAGE_FOR_DELIVERY";
      } else {
        throw Exception("Erreur (${response.statusCode}) : ${response.body}");
      }
    } catch (e) {
      throw Exception("Erreur lors du démarrage de la livraison : $e");
    }
  }

  Future<String?> confirmReceiving(int id, int? userId,
      [DateTime? confirmDate]) async {
    String urlStr = "$baseUrl/containers/delivery-received/$id?userId=$userId";
    if (confirmDate != null) {
      final formattedDate = confirmDate.toIso8601String();
      urlStr += "&confirmDate=$formattedDate";
    }
    final url = Uri.parse(urlStr);

    try {
      final response = await http.get(url);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return "SUCCESS";
      } else if (response.statusCode == 409 &&
          response.body ==
              'Impossible de confirmer la réception, pas de colis dans le conteneur.') {
        return "NO_PACKAGE_FOR_DELIVERY";
      } else if (response.statusCode == 409 &&
          response.body == 'Le conteneur n\'est pas en status INPROGRESS.') {
        return "CONTAINER_NOT_IN_PROGRESS";
      } else {
        throw Exception("Erreur (${response.statusCode}) : ${response.body}");
      }
    } catch (e) {
      throw Exception("Erreur lors du démarrage de la livraison : $e");
    }
  }

  Future<String?> update(int id, int? userId, Containers dto) async {
    try {
      final url = Uri.parse('$baseUrl/containers/update/$id?userId=$userId');
      final headers = {'Content-Type': 'application/json'};

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(dto.toJson()),
      );

      if (response.statusCode == 409 &&
          response.body == 'Ce conteneur existe déjà !') {
        return "REF_EXIST";
      }

      if (response.statusCode == 201) {
        return "UPDATED";
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Échec de la mise à jour');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> embarquerContainerToHarbor(
      HarborEmbarquementRequest request, int userId) async {
    try {
      final url =
          Uri.parse('$baseUrl/containers/embarquer/in-harbor?userId=$userId');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == HttpStatus.created) {
        return "SUCCESS";
      } else if (response.statusCode == HttpStatus.conflict) {
        final errorMessage = response.body;

        if (errorMessage.contains("Le port n'est pas disponible")) {
          return "HARBOR_NOT_AVAILABLE";
        } else if (errorMessage.contains("est déjà dans le port")) {
          return "CONTAINER_ALREADY_IN_ANOTHER_HARBOR";
        }
        return "CONFLICT_ERROR";
      } else if (response.statusCode == HttpStatus.notFound) {
        return "HARBOR_NOT_FOUND";
      } else {
        return "SERVER_ERROR: ${response.statusCode}";
      }
    } catch (e) {
      return "UNEXPECTED_ERROR: ${e.toString()}";
    }
  }
}
