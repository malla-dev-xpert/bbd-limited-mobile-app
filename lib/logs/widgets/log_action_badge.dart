import 'package:flutter/material.dart';
import 'package:bbd_limited/core/enums/log_action.dart';

/// Badge d'action pour les logs
/// Affiche l'icône et le texte de l'action avec la couleur appropriée
class LogActionBadge extends StatelessWidget {
  final LogAction action;
  final String? customText;
  final double? fontSize;
  final EdgeInsets? padding;

  const LogActionBadge({
    super.key,
    required this.action,
    this.customText,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getActionColor(action);
    final icon = _getActionIcon(action);
    final text = customText ?? _getActionText(action);

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: fontSize != null ? fontSize! * 0.9 : 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize ?? 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(LogAction action) {
    switch (action) {
      case LogAction.CREATE:
        return Colors.green;
      case LogAction.UPDATE:
        return Colors.blue;
      case LogAction.DELETE:
        return Colors.red;
      case LogAction.BULK:
        return Colors.deepPurple;
      case LogAction.PAYMENT:
      case LogAction.DEPOSIT:
        return Colors.orange;
      case LogAction.VALIDATE:
        return Colors.teal;
      case LogAction.CANCEL:
        return Colors.orange;
      case LogAction.DELIVERY:
        return Colors.purple;
      case LogAction.EMBARKATION:
        return Colors.cyan;
      case LogAction.WITHDRAWAL:
        return Colors.indigo;
      case LogAction.CONVERSION:
        return Colors.amber;
      case LogAction.LOGIN:
        return Colors.blueGrey;
      case LogAction.UNKNOWN:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(LogAction action) {
    switch (action) {
      case LogAction.CREATE:
        return Icons.add_circle;
      case LogAction.UPDATE:
        return Icons.edit;
      case LogAction.DELETE:
        return Icons.delete;
      case LogAction.BULK:
        return Icons.layers;
      case LogAction.PAYMENT:
        return Icons.payment;
      case LogAction.DEPOSIT:
        return Icons.account_balance_wallet;
      case LogAction.VALIDATE:
        return Icons.check_circle;
      case LogAction.CANCEL:
        return Icons.cancel;
      case LogAction.DELIVERY:
        return Icons.local_shipping;
      case LogAction.EMBARKATION:
        return Icons.flight_takeoff;
      case LogAction.WITHDRAWAL:
        return Icons.remove_circle;
      case LogAction.CONVERSION:
        return Icons.swap_horiz;
      case LogAction.LOGIN:
        return Icons.login;
      case LogAction.UNKNOWN:
        return Icons.history;
    }
  }

  String _getActionText(LogAction action) {
    switch (action) {
      case LogAction.CREATE:
        return 'CRÉATION';
      case LogAction.UPDATE:
        return 'MODIFICATION';
      case LogAction.DELETE:
        return 'SUPPRESSION';
      case LogAction.BULK:
        return 'ACTION GROUPÉE';
      case LogAction.PAYMENT:
        return 'PAIEMENT';
      case LogAction.DEPOSIT:
        return 'VERSEMENT';
      case LogAction.VALIDATE:
        return 'VALIDATION';
      case LogAction.CANCEL:
        return 'ANNULATION';
      case LogAction.DELIVERY:
        return 'LIVRAISON';
      case LogAction.EMBARKATION:
        return 'EMBARQUEMENT';
      case LogAction.WITHDRAWAL:
        return 'RETRAIT';
      case LogAction.CONVERSION:
        return 'CONVERSION';
      case LogAction.LOGIN:
        return 'CONNEXION';
      case LogAction.UNKNOWN:
        return 'ACTION';
    }
  }
}
