/// Enum représentant les actions possibles sur les entités
/// Aligné avec le backend Spring Boot
enum LogAction {
  CREATE,
  UPDATE,
  DELETE,
  VALIDATE,
  CANCEL,
  DELIVERY,
  PAYMENT,
  EMBARKATION,
  WITHDRAWAL,
  DEPOSIT,
  CONVERSION,
  BULK,
  LOGIN,
  UNKNOWN;

  /// Parse depuis une chaîne (backend peut retourner String ou enum)
  static LogAction fromString(String? value) {
    if (value == null || value.isEmpty) return UNKNOWN;

    final upperValue = value.toUpperCase().trim();

    try {
      return LogAction.values.firstWhere(
        (e) => e.name == upperValue,
        orElse: () => _parseFromLegacyCode(upperValue),
      );
    } catch (e) {
      return _parseFromLegacyCode(upperValue);
    }
  }

  /// Parse depuis les anciens codes d'action (rétrocompatibilité)
  static LogAction _parseFromLegacyCode(String code) {
    if (code.contains('CREATION') ||
        code.contains('CREATE') ||
        code.contains('NEW_')) {
      return CREATE;
    } else if (code.contains('MODIFICATION') ||
        code.contains('UPDATE') ||
        code.contains('EDIT')) {
      return UPDATE;
    } else if (code.contains('SUPPRESSION') ||
        code.contains('DELETE') ||
        code.contains('REMOVE')) {
      return DELETE;
    } else if (code.contains('VALIDATION') || code.contains('VALIDATE')) {
      return VALIDATE;
    } else if (code.contains('ANNULATION') || code.contains('CANCEL')) {
      return CANCEL;
    } else if (code.contains('LIVRAISON') || code.contains('DELIVERY')) {
      return DELIVERY;
    } else if (code.contains('PAIEMENT') || code.contains('PAYMENT')) {
      return PAYMENT;
    } else if (code.contains('EMBARQUEMENT') || code.contains('EMBARKATION')) {
      return EMBARKATION;
    } else if (code.contains('RETRAIT') || code.contains('WITHDRAWAL')) {
      return WITHDRAWAL;
    } else if (code.contains('VERSEMENT') || code.contains('DEPOSIT')) {
      return DEPOSIT;
    } else if (code.contains('CONVERSION') || code.contains('CONVERT')) {
      return CONVERSION;
    } else if (code.contains('BULK') || code.contains('MULTIPLE')) {
      return BULK;
    } else if (code.contains('LOGIN') || code.contains('CONNEXION')) {
      return LOGIN;
    }
    return UNKNOWN;
  }

  /// Retourne true si l'action nécessite un affichage before/after
  /// Pour UPDATE, DELETE et VALIDATE uniquement
  bool get requiresBeforeAfter {
    return this == UPDATE || this == DELETE || this == VALIDATE;
  }

  /// Retourne true si l'action est une suppression
  bool get isDelete => this == DELETE;

  /// Retourne true si l'action est une modification
  bool get isUpdate => this == UPDATE;

  /// Retourne true si l'action est une action groupée
  bool get isBulk => this == BULK;

  /// Retourne true si l'action est une connexion
  bool get isLogin => this == LOGIN;
}
