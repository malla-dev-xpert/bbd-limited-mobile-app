import 'package:bbd_limited/models/invoice_options.dart';

/// Marge sélective appliquée à un article spécifique
class SelectiveItemMargin {
  /// ID de l'article (pour l'identifier de manière unique)
  final int itemId;

  /// Type de marge (pourcentage ou montant fixe)
  final MarginType type;

  /// Valeur de la marge
  final double value;

  /// Prix unitaire original (avant marge)
  final double originalUnitPrice;

  /// Prix total original (avant marge)
  final double originalTotalPrice;

  /// Prix unitaire avec marge appliquée
  double get adjustedUnitPrice {
    if (type == MarginType.percentage) {
      return originalUnitPrice * (1 + value / 100);
    } else {
      return originalUnitPrice +
          (value / (originalTotalPrice / originalUnitPrice));
    }
  }

  /// Prix total avec marge appliquée
  double get adjustedTotalPrice {
    if (type == MarginType.percentage) {
      return originalTotalPrice * (1 + value / 100);
    } else {
      return originalTotalPrice + value;
    }
  }

  /// Montant de la marge appliquée
  double get marginAmount {
    return adjustedTotalPrice - originalTotalPrice;
  }

  const SelectiveItemMargin({
    required this.itemId,
    required this.type,
    required this.value,
    required this.originalUnitPrice,
    required this.originalTotalPrice,
  });

  /// Copie avec modifications
  SelectiveItemMargin copyWith({
    int? itemId,
    MarginType? type,
    double? value,
    double? originalUnitPrice,
    double? originalTotalPrice,
  }) {
    return SelectiveItemMargin(
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      value: value ?? this.value,
      originalUnitPrice: originalUnitPrice ?? this.originalUnitPrice,
      originalTotalPrice: originalTotalPrice ?? this.originalTotalPrice,
    );
  }

  /// Conversion en JSON
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'type': type.name,
      'value': value,
      'originalUnitPrice': originalUnitPrice,
      'originalTotalPrice': originalTotalPrice,
    };
  }

  /// Création depuis JSON
  factory SelectiveItemMargin.fromJson(Map<String, dynamic> json) {
    return SelectiveItemMargin(
      itemId: json['itemId'] as int,
      type: MarginType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MarginType.percentage,
      ),
      value: (json['value'] as num).toDouble(),
      originalUnitPrice: (json['originalUnitPrice'] as num).toDouble(),
      originalTotalPrice: (json['originalTotalPrice'] as num).toDouble(),
    );
  }
}

/// Marge sélective appliquée à un frais spécifique
class SelectiveFeeMargin {
  /// ID du frais (pour l'identifier de manière unique)
  final String feeId;

  /// Nom du frais
  final String feeName;

  /// Type de marge (pourcentage ou montant fixe)
  final MarginType type;

  /// Valeur de la marge
  final double value;

  /// Montant original du frais (avant marge)
  final double originalAmount;

  /// Montant du frais avec marge appliquée
  double get adjustedAmount {
    if (type == MarginType.percentage) {
      return originalAmount * (1 + value / 100);
    } else {
      return originalAmount + value;
    }
  }

  /// Montant de la marge appliquée
  double get marginAmount {
    return adjustedAmount - originalAmount;
  }

  const SelectiveFeeMargin({
    required this.feeId,
    required this.feeName,
    required this.type,
    required this.value,
    required this.originalAmount,
  });

  /// Copie avec modifications
  SelectiveFeeMargin copyWith({
    String? feeId,
    String? feeName,
    MarginType? type,
    double? value,
    double? originalAmount,
  }) {
    return SelectiveFeeMargin(
      feeId: feeId ?? this.feeId,
      feeName: feeName ?? this.feeName,
      type: type ?? this.type,
      value: value ?? this.value,
      originalAmount: originalAmount ?? this.originalAmount,
    );
  }

  /// Conversion en JSON
  Map<String, dynamic> toJson() {
    return {
      'feeId': feeId,
      'feeName': feeName,
      'type': type.name,
      'value': value,
      'originalAmount': originalAmount,
    };
  }

  /// Création depuis JSON
  factory SelectiveFeeMargin.fromJson(Map<String, dynamic> json) {
    return SelectiveFeeMargin(
      feeId: json['feeId'] as String,
      feeName: json['feeName'] as String,
      type: MarginType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MarginType.percentage,
      ),
      value: (json['value'] as num).toDouble(),
      originalAmount: (json['originalAmount'] as num).toDouble(),
    );
  }
}

/// Remise sélective appliquée à un article spécifique
class SelectiveLineDiscount {
  /// ID de l'article (pour l'identifier de manière unique)
  final int itemId;

  /// Type de remise (pourcentage ou montant fixe)
  final DiscountType type;

  /// Valeur de la remise
  final double value;

  /// Prix unitaire original (avant remise)
  final double originalUnitPrice;

  /// Prix total original (avant remise)
  final double originalTotalPrice;

  /// Prix unitaire avec remise appliquée
  double get adjustedUnitPrice {
    if (type == DiscountType.percentage) {
      return originalUnitPrice * (1 - value / 100);
    } else {
      // Pour montant fixe, on soustrait proportionnellement
      final ratio = originalTotalPrice > 0 ? value / originalTotalPrice : 0;
      return originalUnitPrice * (1 - ratio);
    }
  }

  /// Prix total avec remise appliquée
  double get adjustedTotalPrice {
    if (type == DiscountType.percentage) {
      return originalTotalPrice * (1 - value / 100);
    } else {
      return (originalTotalPrice - value).clamp(0.0, double.infinity);
    }
  }

  /// Montant de la remise appliquée
  double get discountAmount {
    return originalTotalPrice - adjustedTotalPrice;
  }

  const SelectiveLineDiscount({
    required this.itemId,
    required this.type,
    required this.value,
    required this.originalUnitPrice,
    required this.originalTotalPrice,
  });

  /// Copie avec modifications
  SelectiveLineDiscount copyWith({
    int? itemId,
    DiscountType? type,
    double? value,
    double? originalUnitPrice,
    double? originalTotalPrice,
  }) {
    return SelectiveLineDiscount(
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      value: value ?? this.value,
      originalUnitPrice: originalUnitPrice ?? this.originalUnitPrice,
      originalTotalPrice: originalTotalPrice ?? this.originalTotalPrice,
    );
  }

  /// Conversion en JSON
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'type': type.name,
      'value': value,
      'originalUnitPrice': originalUnitPrice,
      'originalTotalPrice': originalTotalPrice,
    };
  }

  /// Création depuis JSON
  factory SelectiveLineDiscount.fromJson(Map<String, dynamic> json) {
    return SelectiveLineDiscount(
      itemId: json['itemId'] as int,
      type: DiscountType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DiscountType.percentage,
      ),
      value: (json['value'] as num).toDouble(),
      originalUnitPrice: (json['originalUnitPrice'] as num).toDouble(),
      originalTotalPrice: (json['originalTotalPrice'] as num).toDouble(),
    );
  }
}

/// Résultat du calcul avec marges sélectives
class SelectiveMarginCalculationResult {
  /// Sous-total des articles sans marge
  final double subtotal;

  /// Total des marges appliquées aux articles sélectionnés
  final double totalItemMargins;

  /// Total des marges appliquées aux frais sélectionnés
  final double totalFeeMargins;

  /// Sous-total après marges sur articles
  final double subtotalAfterItemMargins;

  /// Total après toutes les marges (sauf marge globale)
  final double totalAfterSelectiveMargins;

  /// Total final avec marge globale (si activée)
  final double finalTotal;

  /// Détails des marges par article
  final Map<int, SelectiveItemMargin> itemMargins;

  /// Détails des marges par frais
  final Map<String, SelectiveFeeMargin> feeMargins;

  const SelectiveMarginCalculationResult({
    required this.subtotal,
    required this.totalItemMargins,
    required this.totalFeeMargins,
    required this.subtotalAfterItemMargins,
    required this.totalAfterSelectiveMargins,
    required this.finalTotal,
    required this.itemMargins,
    required this.feeMargins,
  });
}
