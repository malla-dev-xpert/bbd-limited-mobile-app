/// Mapper pour extraire les données métier depuis entityDetails
/// Exclut systématiquement tous les IDs techniques
class EntityDetailsMapper {
  /// Liste des clés à exclure (IDs et références techniques)
  static const Set<String> excludedKeys = {
    'id',
    'entityId',
    'entityIds',
    'userId',
    'supplierId',
    'partnerId',
    'clientId',
    'customerId',
    'warehouseId',
    'containerId',
    'harborId',
    'deviseId',
    'currencyId',
    'categoryId',
    'carrierId',
    'countryId',
    'invoiceId',
    'purchaseId',
    'paymentId',
    'depositId',
    'embarkationId',
    'withdrawalId',
    'packageId',
    'itemId',
    'createdBy',
    'updatedBy',
    'createdById',
    'updatedById',
    'count', // Pour les actions groupées
  };

  /// Filtre les clés techniques et retourne uniquement les données métier
  static Map<String, dynamic> filterBusinessData(
    Map<String, dynamic>? entityDetails,
  ) {
    if (entityDetails == null || entityDetails.isEmpty) {
      return {};
    }

    final filtered = <String, dynamic>{};

    entityDetails.forEach((key, value) {
      // Exclure les clés techniques
      if (_shouldExcludeKey(key)) {
        return;
      }

      // Exclure les valeurs null, vides ou invalides
      if (_shouldExcludeValue(value)) {
        return;
      }

      // Inclure la clé-valeur
      filtered[key] = value;
    });

    return filtered;
  }

  /// Vérifie si une clé doit être exclue
  static bool _shouldExcludeKey(String key) {
    final keyLower = key.toLowerCase();

    // Vérifier dans la liste d'exclusion
    if (excludedKeys.contains(keyLower)) {
      return true;
    }

    // Exclure les clés se terminant par "Id" ou "ID"
    if (keyLower.endsWith('id') || keyLower.endsWith('ids')) {
      return true;
    }

    return false;
  }

  /// Vérifie si une valeur doit être exclue
  static bool _shouldExcludeValue(dynamic value) {
    if (value == null) return true;
    if (value is String && value.trim().isEmpty) return true;
    if (value is List && value.isEmpty) return true;
    if (value is Map && value.isEmpty) return true;
    return false;
  }

  /// Extrait les données "before" depuis entityDetails
  /// Le backend peut retourner before dans entityDetails ou dans un champ séparé
  /// Supporte aussi initialState
  static Map<String, dynamic>? extractBeforeData(
    Map<String, dynamic>? entityDetails,
  ) {
    if (entityDetails == null) return null;

    // Le backend peut retourner before dans entityDetails['before']
    if (entityDetails.containsKey('before')) {
      final before = entityDetails['before'];
      if (before is Map<String, dynamic>) {
        return filterBusinessData(before);
      }
    }

    // Support du nouveau format : initialState dans entityDetails
    if (entityDetails.containsKey('initialState')) {
      final initialState = entityDetails['initialState'];
      if (initialState is Map<String, dynamic>) {
        return filterBusinessData(initialState);
      }
    }

    return null;
  }

  /// Extrait les données "after" depuis entityDetails
  /// Supporte aussi finalState (nouveau format backend)
  static Map<String, dynamic>? extractAfterData(
    Map<String, dynamic>? entityDetails,
  ) {
    if (entityDetails == null) return null;

    // Le backend peut retourner after dans entityDetails['after']
    if (entityDetails.containsKey('after')) {
      final after = entityDetails['after'];
      if (after is Map<String, dynamic>) {
        return filterBusinessData(after);
      }
    }

    // Support du nouveau format : finalState dans entityDetails
    if (entityDetails.containsKey('finalState')) {
      final finalState = entityDetails['finalState'];
      if (finalState is Map<String, dynamic>) {
        return filterBusinessData(finalState);
      }
    }

    // Si pas de 'after' ou 'finalState', utiliser entityDetails directement (pour CREATE)
    // mais filtrer les IDs
    return filterBusinessData(entityDetails);
  }

  /// Extrait les données "before" depuis initialState (nouveau format backend)
  /// Utilisé quand initialState est fourni directement dans LogDetail
  /// Garde les valeurs null/vides pour permettre la comparaison
  static Map<String, dynamic>? extractBeforeFromInitialState(
    Map<String, dynamic>? initialState,
  ) {
    if (initialState == null) return null;
    return filterBusinessDataForComparison(initialState);
  }

  /// Extrait les données "after" depuis finalState (nouveau format backend)
  /// Utilisé quand finalState est fourni directement dans LogDetail
  /// Garde les valeurs null/vides pour permettre la comparaison
  static Map<String, dynamic>? extractAfterFromFinalState(
    Map<String, dynamic>? finalState,
  ) {
    if (finalState == null) return null;
    return filterBusinessDataForComparison(finalState);
  }

  /// Filtre les clés techniques mais garde les valeurs null/vides pour la comparaison
  /// Utilisé pour initialState/finalState afin de détecter les changements
  static Map<String, dynamic> filterBusinessDataForComparison(
    Map<String, dynamic>? entityDetails,
  ) {
    if (entityDetails == null || entityDetails.isEmpty) {
      return {};
    }

    final filtered = <String, dynamic>{};

    entityDetails.forEach((key, value) {
      // Exclure uniquement les clés techniques (IDs)
      if (_shouldExcludeKey(key)) {
        return;
      }

      // GARDER les valeurs null et vides pour la comparaison
      // Cela permet de détecter les changements entre "" et "DIARRA" par exemple
      filtered[key] = value;
    });

    return filtered;
  }

  /// Extrait les données principales (sans before/after)
  /// Utilisé pour CREATE et autres actions sans historique
  static Map<String, dynamic> extractMainData(
    Map<String, dynamic>? entityDetails,
  ) {
    if (entityDetails == null) return {};

    // Si entityDetails contient 'before' ou 'after', ne pas les utiliser ici
    // (ils seront gérés séparément)
    if (entityDetails.containsKey('before') ||
        entityDetails.containsKey('after')) {
      return {};
    }

    return filterBusinessData(entityDetails);
  }

  /// Compare deux maps et retourne les différences
  /// Retourne une map avec les clés qui ont changé et leurs valeurs before/after
  static Map<String, Map<String, dynamic>> computeDifferences(
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
  ) {
    final differences = <String, Map<String, dynamic>>{};

    if (before == null && after == null) return differences;
    if (before == null) {
      // Tous les champs de after sont nouveaux
      after?.forEach((key, value) {
        differences[key] = {
          'before': null,
          'after': value,
        };
      });
      return differences;
    }
    if (after == null) {
      // Tous les champs de before ont été supprimés
      before.forEach((key, value) {
        differences[key] = {
          'before': value,
          'after': null,
        };
      });
      return differences;
    }

    // Collecter toutes les clés uniques
    final allKeys = <String>{};
    allKeys.addAll(before.keys);
    allKeys.addAll(after.keys);

    // Comparer chaque clé
    for (final key in allKeys) {
      final beforeValue = before[key];
      final afterValue = after[key];

      // Comparer les valeurs (deep comparison pour les maps)
      if (!_areValuesEqual(beforeValue, afterValue)) {
        differences[key] = {
          'before': beforeValue,
          'after': afterValue,
        };
      }
    }

    return differences;
  }

  /// Compare deux valeurs (deep comparison)
  /// Gère les cas null, strings vides, et normalise les comparaisons
  static bool _areValuesEqual(dynamic a, dynamic b) {
    // Normaliser null et strings vides pour la comparaison
    final normalizedA = _normalizeValue(a);
    final normalizedB = _normalizeValue(b);

    if (normalizedA == null && normalizedB == null) return true;
    if (normalizedA == null || normalizedB == null) return false;
    if (normalizedA == normalizedB) return true;

    // Comparaison pour les maps
    if (normalizedA is Map && normalizedB is Map) {
      if (normalizedA.length != normalizedB.length) return false;
      for (final key in normalizedA.keys) {
        if (!normalizedB.containsKey(key)) return false;
        if (!_areValuesEqual(normalizedA[key], normalizedB[key])) return false;
      }
      return true;
    }

    // Comparaison pour les listes
    if (normalizedA is List && normalizedB is List) {
      if (normalizedA.length != normalizedB.length) return false;
      for (int i = 0; i < normalizedA.length; i++) {
        if (!_areValuesEqual(normalizedA[i], normalizedB[i])) return false;
      }
      return true;
    }

    return false;
  }

  /// Normalise une valeur pour la comparaison
  /// null et "" sont considérés comme différents (pour détecter les changements)
  static dynamic _normalizeValue(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      // Garder les strings vides telles quelles pour détecter les changements
      // "" != null et "" != "DIARRA" doivent être détectés
      return value;
    }
    return value;
  }
}
