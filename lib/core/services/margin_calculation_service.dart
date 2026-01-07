import 'package:bbd_limited/models/invoice_options.dart';
import 'package:bbd_limited/models/selective_margin.dart';
import 'package:bbd_limited/models/achats/achat.dart';

/// Service centralisé pour le calcul des marges sélectives
class MarginCalculationService {
  /// Calcule le total avec les marges sélectives appliquées
  ///
  /// [subtotal] : Sous-total initial
  /// [items] : Liste des articles
  /// [options] : Options de facturation (incluant les marges sélectives)
  /// [selectiveItemMargins] : Map des marges par article (itemId -> SelectiveItemMargin)
  /// [selectiveFeeMargins] : Map des marges par frais (feeId -> SelectiveFeeMargin)
  static SelectiveMarginCalculationResult calculateWithSelectiveMargins({
    required double subtotal,
    required List<Items> items,
    required InvoiceOptions options,
    Map<int, SelectiveItemMargin> selectiveItemMargins = const {},
    Map<String, SelectiveFeeMargin> selectiveFeeMargins = const {},
  }) {
    // Calculer le sous-total avec les marges sur articles sélectionnés
    double subtotalAfterItemMargins = subtotal;
    double totalItemMargins = 0.0;

    for (final item in items) {
      if (item.id != null && selectiveItemMargins.containsKey(item.id)) {
        final margin = selectiveItemMargins[item.id]!;
        totalItemMargins += margin.marginAmount;
        subtotalAfterItemMargins += margin.marginAmount;
      }
    }

    // IMPORTANT: Si des marges sélectives sont activées, ne pas appliquer la marge par ligne globale
    // La marge par ligne globale est remplacée par les marges sélectives

    // Marge par ligne globale (seulement si aucune marge sélective n'est activée)
    double totalAfterLineMargin = subtotalAfterItemMargins;
    if (options.enableLineMargin &&
        options.lineMarginValue != null &&
        !options.enableSelectiveItemMargins) {
      if (options.lineMarginType == MarginType.percentage) {
        totalAfterLineMargin +=
            (subtotalAfterItemMargins * options.lineMarginValue! / 100);
      } else {
        totalAfterLineMargin += options.lineMarginValue!;
      }
    }

    // Remise par ligne (appliquée après la marge par ligne)
    double totalAfterLineDiscount = totalAfterLineMargin;
    if (options.enableLineDiscount && options.lineDiscountValue != null) {
      if (options.lineDiscountType == DiscountType.percentage) {
        totalAfterLineDiscount -=
            (totalAfterLineMargin * options.lineDiscountValue! / 100);
      } else {
        totalAfterLineDiscount -= options.lineDiscountValue!;
      }
    }

    // Remise globale (si activée)
    double totalAfterDiscount = totalAfterLineDiscount;
    if (options.enableDiscount && options.discountValue != null) {
      if (options.discountType == DiscountType.percentage) {
        totalAfterDiscount -=
            (totalAfterLineDiscount * options.discountValue! / 100);
      } else {
        totalAfterDiscount -= options.discountValue!;
      }
    }

    // Calculer les marges sur frais sélectionnés
    double totalFeeMargins = 0.0;
    double totalAfterFeeMargins = totalAfterDiscount;

    // Frais d'entreposage (si activé et non sélectionné pour marge sélective)
    if (options.enableStorageFees &&
        options.storageFeeAmount != null &&
        !selectiveFeeMargins.containsKey('storage_fees')) {
      if (options.storageFeeType == StorageFeeType.percentage) {
        totalAfterFeeMargins +=
            (subtotalAfterItemMargins * options.storageFeeAmount! / 100);
      } else {
        totalAfterFeeMargins += options.storageFeeAmount!;
      }
    }

    // Frais additionnels (si activés et non sélectionnés pour marge sélective)
    if (options.enableAdditionalFees) {
      for (final fee in options.additionalFees) {
        if (fee.isActive &&
            !selectiveFeeMargins.containsKey('fee_${fee.name}')) {
          if (fee.type == FeeType.percentage) {
            totalAfterFeeMargins +=
                (subtotalAfterItemMargins * fee.amount / 100);
          } else {
            totalAfterFeeMargins += fee.amount;
          }
        }
      }
    }

    // Appliquer les marges sélectives sur les frais
    for (final feeMargin in selectiveFeeMargins.values) {
      totalFeeMargins += feeMargin.marginAmount;
      totalAfterFeeMargins += feeMargin.marginAmount;
    }

    // Marge globale (appliquée en dernier, toujours sur le total)
    double finalTotal = totalAfterFeeMargins;
    if (options.enableGlobalMargin && options.globalMarginValue != null) {
      if (options.globalMarginType == MarginType.percentage) {
        finalTotal += (finalTotal * options.globalMarginValue! / 100);
      } else {
        finalTotal += options.globalMarginValue!;
      }
    }

    return SelectiveMarginCalculationResult(
      subtotal: subtotal,
      totalItemMargins: totalItemMargins,
      totalFeeMargins: totalFeeMargins,
      subtotalAfterItemMargins: subtotalAfterItemMargins,
      totalAfterSelectiveMargins: totalAfterFeeMargins,
      finalTotal: finalTotal,
      itemMargins: selectiveItemMargins,
      feeMargins: selectiveFeeMargins,
    );
  }

  /// Calcule le sous-total original à partir des articles (sans marges)
  static double calculateOriginalSubtotal(List<Items> items) {
    return items.fold(0.0, (sum, item) => sum + (item.totalPrice ?? 0.0));
  }

  /// Calcule le prix ajusté d'un article avec sa marge sélective
  static double calculateItemAdjustedPrice({
    required Items item,
    SelectiveItemMargin? margin,
  }) {
    if (margin == null) {
      return item.totalPrice ?? 0.0;
    }
    return margin.adjustedTotalPrice;
  }

  /// Calcule le montant ajusté d'un frais avec sa marge sélective
  static double calculateFeeAdjustedAmount({
    required double originalAmount,
    SelectiveFeeMargin? margin,
  }) {
    if (margin == null) {
      return originalAmount;
    }
    return margin.adjustedAmount;
  }
}
