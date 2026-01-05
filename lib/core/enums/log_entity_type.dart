/// Enum représentant les types d'entités dans le système
/// Aligné avec le backend Spring Boot
enum LogEntityType {
  CATEGORY,
  ITEM,
  HARBOR,
  PACKAGE,
  USER,
  PARTNER,
  SUPPLIER,
  CUSTOMER,
  CONTAINER,
  WAREHOUSE,
  CURRENCY,
  PAYMENT,
  DEPOSIT,
  PURCHASE,
  CASH_WITHDRAWAL,
  EMBARKATION,
  INVOICE,
  UNKNOWN;

  /// Parse depuis une chaîne (backend peut retourner String ou enum)
  static LogEntityType fromString(String? value) {
    if (value == null || value.isEmpty) return UNKNOWN;
    
    final upperValue = value.toUpperCase().trim();
    
    try {
      return LogEntityType.values.firstWhere(
        (e) => e.name == upperValue,
        orElse: () => _parseFromLegacyName(upperValue),
      );
    } catch (e) {
      return _parseFromLegacyName(upperValue);
    }
  }

  /// Parse depuis les anciens noms d'entités (rétrocompatibilité)
  static LogEntityType _parseFromLegacyName(String name) {
    if (name.contains('CATEGORIE') || name.contains('CATEGORY')) {
      return CATEGORY;
    } else if (name.contains('ARTICLE') || name.contains('ITEM')) {
      return ITEM;
    } else if (name.contains('PORT') || name.contains('HARBOR')) {
      return HARBOR;
    } else if (name.contains('COLIS') || name.contains('PACKAGE')) {
      return PACKAGE;
    } else if (name.contains('UTILISATEUR') || name.contains('USER')) {
      return USER;
    } else if (name.contains('PARTENAIRE') || name.contains('PARTNER')) {
      return PARTNER;
    } else if (name.contains('FOURNISSEUR') || name.contains('SUPPLIER')) {
      return SUPPLIER;
    } else if (name.contains('CLIENT') || name.contains('CUSTOMER')) {
      return CUSTOMER;
    } else if (name.contains('CONTENEUR') || name.contains('CONTAINER')) {
      return CONTAINER;
    } else if (name.contains('ENTREPOT') || name.contains('WAREHOUSE')) {
      return WAREHOUSE;
    } else if (name.contains('DEVISE') || name.contains('CURRENCY')) {
      return CURRENCY;
    } else if (name.contains('PAIEMENT') || name.contains('PAYMENT')) {
      return PAYMENT;
    } else if (name.contains('VERSEMENT') || name.contains('DEPOSIT')) {
      return DEPOSIT;
    } else if (name.contains('ACHAT') || name.contains('PURCHASE')) {
      return PURCHASE;
    } else if (name.contains('RETRAIT') || name.contains('WITHDRAWAL')) {
      return CASH_WITHDRAWAL;
    } else if (name.contains('EMBARQUEMENT') || name.contains('EMBARKATION')) {
      return EMBARKATION;
    } else if (name.contains('FACTURE') || name.contains('INVOICE')) {
      return INVOICE;
    }
    return UNKNOWN;
  }

  /// Retourne le nom d'affichage en français
  String get displayName {
    switch (this) {
      case LogEntityType.CATEGORY:
        return 'catégorie';
      case LogEntityType.ITEM:
        return 'article';
      case LogEntityType.HARBOR:
        return 'port';
      case LogEntityType.PACKAGE:
        return 'colis';
      case LogEntityType.USER:
        return 'utilisateur';
      case LogEntityType.PARTNER:
        return 'partenaire';
      case LogEntityType.SUPPLIER:
        return 'fournisseur';
      case LogEntityType.CUSTOMER:
        return 'client';
      case LogEntityType.CONTAINER:
        return 'conteneur';
      case LogEntityType.WAREHOUSE:
        return 'entrepôt';
      case LogEntityType.CURRENCY:
        return 'devise';
      case LogEntityType.PAYMENT:
        return 'paiement';
      case LogEntityType.DEPOSIT:
        return 'versement';
      case LogEntityType.PURCHASE:
        return 'achat';
      case LogEntityType.CASH_WITHDRAWAL:
        return 'retrait';
      case LogEntityType.EMBARKATION:
        return 'embarquement';
      case LogEntityType.INVOICE:
        return 'facture';
      case LogEntityType.UNKNOWN:
        return 'entité';
    }
  }

  /// Retourne le nom d'affichage au pluriel
  String get displayNamePlural {
    switch (this) {
      case LogEntityType.CATEGORY:
        return 'catégories';
      case LogEntityType.ITEM:
        return 'articles';
      case LogEntityType.HARBOR:
        return 'ports';
      case LogEntityType.PACKAGE:
        return 'colis';
      case LogEntityType.USER:
        return 'utilisateurs';
      case LogEntityType.PARTNER:
        return 'partenaires';
      case LogEntityType.SUPPLIER:
        return 'fournisseurs';
      case LogEntityType.CUSTOMER:
        return 'clients';
      case LogEntityType.CONTAINER:
        return 'conteneurs';
      case LogEntityType.WAREHOUSE:
        return 'entrepôts';
      case LogEntityType.CURRENCY:
        return 'devises';
      case LogEntityType.PAYMENT:
        return 'paiements';
      case LogEntityType.DEPOSIT:
        return 'versements';
      case LogEntityType.PURCHASE:
        return 'achats';
      case LogEntityType.CASH_WITHDRAWAL:
        return 'retraits';
      case LogEntityType.EMBARKATION:
        return 'embarquements';
      case LogEntityType.INVOICE:
        return 'factures';
      case LogEntityType.UNKNOWN:
        return 'entités';
    }
  }
}

