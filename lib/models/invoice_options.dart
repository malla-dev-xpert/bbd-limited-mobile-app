import 'package:bbd_limited/models/selective_margin.dart';

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
  final bool enableLineDiscount;
  final double? lineDiscountValue;
  final DiscountType lineDiscountType;
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

  // Marges sélectives par article
  final bool enableSelectiveItemMargins;
  final Map<int, SelectiveItemMargin> selectiveItemMargins;

  // Marges sélectives par frais
  final bool enableSelectiveFeeMargins;
  final Map<String, SelectiveFeeMargin> selectiveFeeMargins;

  // Remises sélectives par ligne
  final bool enableSelectiveLineDiscounts;
  final Map<int, SelectiveLineDiscount> selectiveLineDiscounts;

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
    this.enableLineDiscount = false,
    this.lineDiscountValue,
    this.lineDiscountType = DiscountType.percentage,
    this.enableDiscount = false,
    this.discountType = DiscountType.percentage,
    this.discountValue,
    this.enableAdditionalFees = false,
    this.additionalFees = const [],
    this.enableStorageFees = false,
    this.storageFeeAmount,
    this.storageFeeType = StorageFeeType.fixed,
    this.enableSelectiveItemMargins = false,
    this.selectiveItemMargins = const {},
    this.enableSelectiveFeeMargins = false,
    this.selectiveFeeMargins = const {},
    this.enableSelectiveLineDiscounts = false,
    this.selectiveLineDiscounts = const {},
  });

  /// Copie avec modifications
  InvoiceOptions copyWith({
    bool? enableLineMargin,
    double? lineMarginValue,
    MarginType? lineMarginType,
    bool? enableGlobalMargin,
    double? globalMarginValue,
    MarginType? globalMarginType,
    bool? enableLineDiscount,
    double? lineDiscountValue,
    DiscountType? lineDiscountType,
    bool? enableDiscount,
    DiscountType? discountType,
    double? discountValue,
    bool? enableAdditionalFees,
    List<AdditionalFee>? additionalFees,
    bool? enableStorageFees,
    double? storageFeeAmount,
    StorageFeeType? storageFeeType,
    bool? enableSelectiveItemMargins,
    Map<int, SelectiveItemMargin>? selectiveItemMargins,
    bool? enableSelectiveFeeMargins,
    Map<String, SelectiveFeeMargin>? selectiveFeeMargins,
    bool? enableSelectiveLineDiscounts,
    Map<int, SelectiveLineDiscount>? selectiveLineDiscounts,
  }) {
    return InvoiceOptions(
      enableLineMargin: enableLineMargin ?? this.enableLineMargin,
      lineMarginValue: lineMarginValue ?? this.lineMarginValue,
      lineMarginType: lineMarginType ?? this.lineMarginType,
      enableGlobalMargin: enableGlobalMargin ?? this.enableGlobalMargin,
      globalMarginValue: globalMarginValue ?? this.globalMarginValue,
      globalMarginType: globalMarginType ?? this.globalMarginType,
      enableLineDiscount: enableLineDiscount ?? this.enableLineDiscount,
      lineDiscountValue: lineDiscountValue ?? this.lineDiscountValue,
      lineDiscountType: lineDiscountType ?? this.lineDiscountType,
      enableDiscount: enableDiscount ?? this.enableDiscount,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      enableAdditionalFees: enableAdditionalFees ?? this.enableAdditionalFees,
      additionalFees: additionalFees ?? this.additionalFees,
      enableStorageFees: enableStorageFees ?? this.enableStorageFees,
      storageFeeAmount: storageFeeAmount ?? this.storageFeeAmount,
      storageFeeType: storageFeeType ?? this.storageFeeType,
      enableSelectiveItemMargins:
          enableSelectiveItemMargins ?? this.enableSelectiveItemMargins,
      selectiveItemMargins: selectiveItemMargins ?? this.selectiveItemMargins,
      enableSelectiveFeeMargins:
          enableSelectiveFeeMargins ?? this.enableSelectiveFeeMargins,
      selectiveFeeMargins: selectiveFeeMargins ?? this.selectiveFeeMargins,
      enableSelectiveLineDiscounts:
          enableSelectiveLineDiscounts ?? this.enableSelectiveLineDiscounts,
      selectiveLineDiscounts:
          selectiveLineDiscounts ?? this.selectiveLineDiscounts,
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
          'La FRAIS DE TRAVAIL doit être entre ${currencyFormat(minAmount)} et ${currencyFormat(maxAmount)}');
    }

    if (enableGlobalMargin &&
        globalMarginType == MarginType.percentage &&
        (globalMarginValue == null ||
            globalMarginValue! < minPercentage ||
            globalMarginValue! > maxPercentage)) {
      errors.add(
          'La FRAIS DE TRAVAIL en pourcentage doit être entre $minPercentage% et $maxPercentage%');
    }

    if (enableLineDiscount &&
        (lineDiscountValue == null ||
            lineDiscountValue! < minAmount ||
            lineDiscountValue! > maxAmount)) {
      errors.add(
          'La remise par ligne doit être entre ${currencyFormat(minAmount)} et ${currencyFormat(maxAmount)}');
    }

    if (enableLineDiscount &&
        lineDiscountType == DiscountType.percentage &&
        (lineDiscountValue == null ||
            lineDiscountValue! < minPercentage ||
            lineDiscountValue! > maxPercentage)) {
      errors.add(
          'La remise par ligne en pourcentage doit être entre $minPercentage% et $maxPercentage%');
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

    // Marge par ligne (seulement si aucune marge sélective n'est activée)
    double totalAfterLineMargin = subtotal;
    if (enableLineMargin &&
        lineMarginValue != null &&
        !enableSelectiveItemMargins) {
      if (lineMarginType == MarginType.percentage) {
        totalAfterLineMargin += (subtotal * lineMarginValue! / 100);
      } else {
        totalAfterLineMargin += lineMarginValue!;
      }
    } else {
      // Si marges sélectives activées, le totalAfterLineMargin reste égal au subtotal
      // (les marges sélectives sont déjà incluses dans le subtotal passé)
      totalAfterLineMargin = subtotal;
    }
    total = totalAfterLineMargin;

    // Remise par ligne (appliquée après la marge par ligne, comme dans MarginCalculationService)
    double totalAfterLineDiscount = totalAfterLineMargin;
    if (enableLineDiscount && lineDiscountValue != null) {
      if (lineDiscountType == DiscountType.percentage) {
        totalAfterLineDiscount -=
            (totalAfterLineMargin * lineDiscountValue! / 100);
      } else {
        totalAfterLineDiscount -= lineDiscountValue!;
      }
    }
    total = totalAfterLineDiscount;

    // Remise globale (appliquée après la remise par ligne, comme dans MarginCalculationService)
    double totalAfterDiscount = totalAfterLineDiscount;
    if (enableDiscount && discountValue != null) {
      if (discountType == DiscountType.percentage) {
        totalAfterDiscount -= (totalAfterLineDiscount * discountValue! / 100);
      } else {
        totalAfterDiscount -= discountValue!;
      }
    }
    total = totalAfterDiscount;

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

    // FRAIS DE TRAVAIL (appliquée en dernier, toujours sur le total)
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
      'enableLineDiscount': enableLineDiscount,
      'lineDiscountValue': lineDiscountValue,
      'lineDiscountType': lineDiscountType.name,
      'enableDiscount': enableDiscount,
      'discountType': discountType.name,
      'discountValue': discountValue,
      'enableAdditionalFees': enableAdditionalFees,
      'additionalFees': additionalFees.map((f) => f.toJson()).toList(),
      'enableStorageFees': enableStorageFees,
      'storageFeeAmount': storageFeeAmount,
      'storageFeeType': storageFeeType.name,
      'enableSelectiveItemMargins': enableSelectiveItemMargins,
      'selectiveItemMargins': selectiveItemMargins.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      ),
      'enableSelectiveFeeMargins': enableSelectiveFeeMargins,
      'selectiveFeeMargins': selectiveFeeMargins.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'enableSelectiveLineDiscounts': enableSelectiveLineDiscounts,
      'selectiveLineDiscounts': selectiveLineDiscounts.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      ),
    };
  }

  /// Création depuis JSON
  factory InvoiceOptions.fromJson(Map<String, dynamic> json) {
    // Parser les marges sélectives par article
    Map<int, SelectiveItemMargin> itemMargins = {};
    if (json['selectiveItemMargins'] != null) {
      final marginsMap = json['selectiveItemMargins'] as Map<String, dynamic>;
      itemMargins = marginsMap.map(
        (key, value) => MapEntry(
          int.parse(key),
          SelectiveItemMargin.fromJson(value as Map<String, dynamic>),
        ),
      );
    }

    // Parser les marges sélectives par frais
    Map<String, SelectiveFeeMargin> feeMargins = {};
    if (json['selectiveFeeMargins'] != null) {
      final marginsMap = json['selectiveFeeMargins'] as Map<String, dynamic>;
      feeMargins = marginsMap.map(
        (key, value) => MapEntry(
          key,
          SelectiveFeeMargin.fromJson(value as Map<String, dynamic>),
        ),
      );
    }

    // Parser les remises sélectives par ligne
    Map<int, SelectiveLineDiscount> lineDiscounts = {};
    if (json['selectiveLineDiscounts'] != null) {
      final discountsMap =
          json['selectiveLineDiscounts'] as Map<String, dynamic>;
      lineDiscounts = discountsMap.map(
        (key, value) => MapEntry(
          int.parse(key),
          SelectiveLineDiscount.fromJson(value as Map<String, dynamic>),
        ),
      );
    }

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
      enableLineDiscount: json['enableLineDiscount'] ?? false,
      lineDiscountValue: json['lineDiscountValue']?.toDouble(),
      lineDiscountType: DiscountType.values.firstWhere(
        (e) => e.name == json['lineDiscountType'],
        orElse: () => DiscountType.percentage,
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
      enableSelectiveItemMargins: json['enableSelectiveItemMargins'] ?? false,
      selectiveItemMargins: itemMargins,
      enableSelectiveFeeMargins: json['enableSelectiveFeeMargins'] ?? false,
      selectiveFeeMargins: feeMargins,
      enableSelectiveLineDiscounts:
          json['enableSelectiveLineDiscounts'] ?? false,
      selectiveLineDiscounts: lineDiscounts,
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
