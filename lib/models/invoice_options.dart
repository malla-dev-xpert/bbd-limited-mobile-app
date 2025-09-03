import 'package:flutter/material.dart';

/// Options configurables pour les factures
class InvoiceOptions {
  // Marges
  final bool enableLineMargin;
  final double? lineMarginValue;
  final MarginType lineMarginType;
  final bool enableGlobalMargin;
  final double? globalMarginValue;
  final MarginType globalMarginType;

  // Remises
  final bool enableDiscount;
  final DiscountType discountType;
  final double? discountValue;

  // Frais optionnels
  final bool enableAdditionalFees;
  final List<AdditionalFee> additionalFees;

  // Frais d'entreposage
  final bool enableStorageFees;
  final double? storageFeeAmount;
  final StorageFeeType storageFeeType;

  // Validation
  static const double maxPercentage = 100.0;
  static const double minPercentage = 0.0;
  static const double maxAmount = 999999.99;
  static const double minAmount = 0.0;

  const InvoiceOptions({
    this.enableLineMargin = false,
    this.lineMarginValue,
    this.lineMarginType = MarginType.percentage,
    this.enableGlobalMargin = false,
    this.globalMarginValue,
    this.globalMarginType = MarginType.percentage,
    this.enableDiscount = false,
    this.discountType = DiscountType.percentage,
    this.discountValue,
    this.enableAdditionalFees = false,
    this.additionalFees = const [],
    this.enableStorageFees = false,
    this.storageFeeAmount,
    this.storageFeeType = StorageFeeType.fixed,
  });

  /// Copie avec modifications
  InvoiceOptions copyWith({
    bool? enableLineMargin,
    double? lineMarginValue,
    MarginType? lineMarginType,
    bool? enableGlobalMargin,
    double? globalMarginValue,
    MarginType? globalMarginType,
    bool? enableDiscount,
    DiscountType? discountType,
    double? discountValue,
    bool? enableAdditionalFees,
    List<AdditionalFee>? additionalFees,
    bool? enableStorageFees,
    double? storageFeeAmount,
    StorageFeeType? storageFeeType,
  }) {
    return InvoiceOptions(
      enableLineMargin: enableLineMargin ?? this.enableLineMargin,
      lineMarginValue: lineMarginValue ?? this.lineMarginValue,
      lineMarginType: lineMarginType ?? this.lineMarginType,
      enableGlobalMargin: enableGlobalMargin ?? this.enableGlobalMargin,
      globalMarginValue: globalMarginValue ?? this.globalMarginValue,
      globalMarginType: globalMarginType ?? this.globalMarginType,
      enableDiscount: enableDiscount ?? this.enableDiscount,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      enableAdditionalFees: enableAdditionalFees ?? this.enableAdditionalFees,
      additionalFees: additionalFees ?? this.additionalFees,
      enableStorageFees: enableStorageFees ?? this.enableStorageFees,
      storageFeeAmount: storageFeeAmount ?? this.storageFeeAmount,
      storageFeeType: storageFeeType ?? this.storageFeeType,
    );
  }

  /// Validation des options
  List<String> validate() {
    final errors = <String>[];

    if (enableLineMargin &&
        (lineMarginValue == null ||
            lineMarginValue! < minAmount ||
            lineMarginValue! > maxAmount)) {
      errors.add(
          'La marge par ligne doit être entre ${currencyFormat(minAmount)} et ${currencyFormat(maxAmount)}');
    }

    if (enableLineMargin &&
        lineMarginType == MarginType.percentage &&
        (lineMarginValue == null ||
            lineMarginValue! < minPercentage ||
            lineMarginValue! > maxPercentage)) {
      errors.add(
          'La marge par ligne en pourcentage doit être entre $minPercentage% et $maxPercentage%');
    }

    if (enableGlobalMargin &&
        (globalMarginValue == null ||
            globalMarginValue! < minAmount ||
            globalMarginValue! > maxAmount)) {
      errors.add(
          'La marge globale doit être entre ${currencyFormat(minAmount)} et ${currencyFormat(maxAmount)}');
    }

    if (enableGlobalMargin &&
        globalMarginType == MarginType.percentage &&
        (globalMarginValue == null ||
            globalMarginValue! < minPercentage ||
            globalMarginValue! > maxPercentage)) {
      errors.add(
          'La marge globale en pourcentage doit être entre $minPercentage% et $maxPercentage%');
    }

    if (enableDiscount &&
        (discountValue == null ||
            discountValue! < minAmount ||
            discountValue! > maxAmount)) {
      errors.add(
          'La remise doit être entre ${currencyFormat(minAmount)} et ${currencyFormat(maxAmount)}');
    }

    if (enableDiscount &&
        discountType == DiscountType.percentage &&
        (discountValue == null ||
            discountValue! < minPercentage ||
            discountValue! > maxPercentage)) {
      errors.add(
          'La remise en pourcentage doit être entre $minPercentage% et $maxPercentage%');
    }

    if (enableStorageFees &&
        (storageFeeAmount == null ||
            storageFeeAmount! < minAmount ||
            storageFeeAmount! > maxAmount)) {
      errors.add(
          'Les frais d\'entreposage doivent être entre ${currencyFormat(minAmount)} et ${currencyFormat(maxAmount)}');
    }

    if (enableStorageFees &&
        storageFeeType == StorageFeeType.percentage &&
        (storageFeeAmount == null ||
            storageFeeAmount! < minPercentage ||
            storageFeeAmount! > maxPercentage)) {
      errors.add(
          'Les frais d\'entreposage en pourcentage doivent être entre $minPercentage% et $maxPercentage%');
    }

    for (final fee in additionalFees) {
      final feeErrors = fee.validate();
      errors.addAll(feeErrors.map((e) => 'Frais "${fee.name}": $e'));
    }

    return errors;
  }

  /// Calcul du total avec toutes les options appliquées
  double calculateTotal(double subtotal) {
    double total = subtotal;

    // Marge par ligne
    if (enableLineMargin && lineMarginValue != null) {
      if (lineMarginType == MarginType.percentage) {
        total += (subtotal * lineMarginValue! / 100);
      } else {
        total += lineMarginValue!;
      }
    }

    // Remise
    if (enableDiscount && discountValue != null) {
      if (discountType == DiscountType.percentage) {
        total -= (total * discountValue! / 100);
      } else {
        total -= discountValue!;
      }
    }

    // Frais additionnels
    if (enableAdditionalFees) {
      for (final fee in additionalFees) {
        if (fee.isActive) {
          if (fee.type == FeeType.percentage) {
            total += (subtotal * fee.amount / 100);
          } else {
            total += fee.amount;
          }
        }
      }
    }

    // Frais d'entreposage
    if (enableStorageFees && storageFeeAmount != null) {
      if (storageFeeType == StorageFeeType.percentage) {
        total += (subtotal * storageFeeAmount! / 100);
      } else {
        total += storageFeeAmount!;
      }
    }

    // Marge globale (appliquée en dernier)
    if (enableGlobalMargin && globalMarginValue != null) {
      if (globalMarginType == MarginType.percentage) {
        total += (total * globalMarginValue! / 100);
      } else {
        total += globalMarginValue!;
      }
    }

    return total;
  }

  /// Conversion en JSON
  Map<String, dynamic> toJson() {
    return {
      'enableLineMargin': enableLineMargin,
      'lineMarginValue': lineMarginValue,
      'lineMarginType': lineMarginType.name,
      'enableGlobalMargin': enableGlobalMargin,
      'globalMarginValue': globalMarginValue,
      'globalMarginType': globalMarginType.name,
      'enableDiscount': enableDiscount,
      'discountType': discountType.name,
      'discountValue': discountValue,
      'enableAdditionalFees': enableAdditionalFees,
      'additionalFees': additionalFees.map((f) => f.toJson()).toList(),
      'enableStorageFees': enableStorageFees,
      'storageFeeAmount': storageFeeAmount,
      'storageFeeType': storageFeeType.name,
    };
  }

  /// Création depuis JSON
  factory InvoiceOptions.fromJson(Map<String, dynamic> json) {
    return InvoiceOptions(
      enableLineMargin: json['enableLineMargin'] ?? false,
      lineMarginValue: json['lineMarginValue']?.toDouble(),
      lineMarginType: MarginType.values.firstWhere(
        (e) => e.name == json['lineMarginType'],
        orElse: () => MarginType.percentage,
      ),
      enableGlobalMargin: json['enableGlobalMargin'] ?? false,
      globalMarginValue: json['globalMarginValue']?.toDouble(),
      globalMarginType: MarginType.values.firstWhere(
        (e) => e.name == json['globalMarginType'],
        orElse: () => MarginType.percentage,
      ),
      enableDiscount: json['enableDiscount'] ?? false,
      discountType: DiscountType.values.firstWhere(
        (e) => e.name == json['discountType'],
        orElse: () => DiscountType.percentage,
      ),
      discountValue: json['discountValue']?.toDouble(),
      enableAdditionalFees: json['enableAdditionalFees'] ?? false,
      additionalFees: (json['additionalFees'] as List<dynamic>?)
              ?.map((f) => AdditionalFee.fromJson(f))
              .toList() ??
          [],
      enableStorageFees: json['enableStorageFees'] ?? false,
      storageFeeAmount: json['storageFeeAmount']?.toDouble(),
      storageFeeType: StorageFeeType.values.firstWhere(
        (e) => e.name == json['storageFeeType'],
        orElse: () => StorageFeeType.fixed,
      ),
    );
  }

  /// Formatage monétaire
  static String currencyFormat(double amount) {
    return '${amount.toStringAsFixed(2)}';
  }
}

/// Types de marge
enum MarginType {
  percentage,
  fixed,
}

/// Types de remise
enum DiscountType {
  percentage,
  fixed,
}

/// Types de frais d'entreposage
enum StorageFeeType {
  fixed,
  percentage,
}

/// Types de frais additionnels
enum FeeType {
  fixed,
  percentage,
}

/// Frais additionnel
class AdditionalFee {
  final String name;
  final double amount;
  final FeeType type;
  final bool isActive;
  final String? description;

  const AdditionalFee({
    required this.name,
    required this.amount,
    this.type = FeeType.fixed,
    this.isActive = true,
    this.description,
  });

  /// Validation du frais
  List<String> validate() {
    final errors = <String>[];

    if (name.trim().isEmpty) {
      errors.add('Le nom est requis');
    }

    if (amount < 0) {
      errors.add('Le montant doit être positif');
    }

    if (type == FeeType.percentage && (amount < 0 || amount > 100)) {
      errors.add('Le pourcentage doit être entre 0% et 100%');
    }

    return errors;
  }

  /// Copie avec modifications
  AdditionalFee copyWith({
    String? name,
    double? amount,
    FeeType? type,
    bool? isActive,
    String? description,
  }) {
    return AdditionalFee(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
    );
  }

  /// Conversion en JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'type': type.name,
      'isActive': isActive,
      'description': description,
    };
  }

  /// Création depuis JSON
  factory AdditionalFee.fromJson(Map<String, dynamic> json) {
    return AdditionalFee(
      name: json['name'] ?? '',
      amount: json['amount']?.toDouble() ?? 0.0,
      type: FeeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FeeType.fixed,
      ),
      isActive: json['isActive'] ?? true,
      description: json['description'],
    );
  }
}
