import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/cbm_pricing.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class CbmPricingListItem extends StatelessWidget {
  final CbmPricing cbmPricing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CbmPricingListItem({
    Key? key,
    required this.cbmPricing,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: Key(cbmPricing.id.toString()),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: AppLocalizations.of(context).translate('edit'),
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: AppLocalizations.of(context).translate('delete'),
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(16)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1E49).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.square_foot,
                  color: Color(0xFF1A1E49),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${cbmPricing.cbmValue} CBM",
                      style: AppTextSize.titleStyle(context, color: const Color(0xFF2C2C2C)),
                    ),
                    if (cbmPricing.currency != null)
                      Text(
                        cbmPricing.currency!,
                        style: AppTextSize.bodyStyle(context, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              Text(
                "${cbmPricing.price}",
                style: AppTextSize.titleStyle(context, color: const Color(0xFF1A1E49)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
