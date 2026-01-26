import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/core/services/access_control_service.dart';
import 'package:bbd_limited/core/services/auth_services.dart';

class VersementListWidget extends StatelessWidget {
  final List<dynamic>? versements;
  final Future<void> Function() onRefresh;
  final Function(Versement) onVersementTap;
  final Function(Versement)? onEditVersement;
  final Function(Versement)? onDeleteVersement;
  final Function(Versement)? onTransferVersement;

  const VersementListWidget({
    Key? key,
    required this.versements,
    required this.onRefresh,
    required this.onVersementTap,
    this.onEditVersement,
    this.onDeleteVersement,
    this.onTransferVersement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (versements == null || versements!.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.2,
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context).translate('no_versements_found'),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100, left: 10, right: 10),
        itemCount: versements?.length ?? 0,
        itemBuilder: (context, index) {
          final versement = versements![index] as Versement;
          final montantRestant = versement.montantRestant ?? 0.0;
          final isNegative = montantRestant < 0;
          final statusColor = isNegative ? Colors.red[400] : Colors.green[400];

          final versementCurrencyFormat = NumberFormat.currency(
            locale: 'fr_FR',
            symbol: versement.deviseCode ?? 'CNY',
          );

          final user = AuthService.currentUser;
          final canDelete =
              user != null && AccessControlService().canDeletePayment(user);

          return Container(
            padding: const EdgeInsets.all(0),
            child: (onEditVersement != null ||
                    (onDeleteVersement != null && canDelete) ||
                    onTransferVersement != null)
                ? Slidable(
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        if (onTransferVersement != null)
                          SlidableAction(
                            onPressed: (context) =>
                                onTransferVersement!(versement),
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            icon: Icons.swap_horiz,
                            label: AppLocalizations.of(context)
                                .translate('transfer'),
                          ),
                        if (onEditVersement != null)
                          SlidableAction(
                            onPressed: (context) => onEditVersement!(versement),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            icon: Icons.edit,
                            label:
                                AppLocalizations.of(context).translate('edit'),
                          ),
                        if (onDeleteVersement != null && canDelete)
                          SlidableAction(
                            onPressed: (context) =>
                                onDeleteVersement!(versement),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: AppLocalizations.of(context)
                                .translate('delete'),
                          ),
                      ],
                    ),
                    child: _buildListTile(context, versement,
                        versementCurrencyFormat, statusColor, isNegative),
                  )
                : _buildListTile(context, versement, versementCurrencyFormat,
                    statusColor, isNegative),
          );
        },
      ),
    );
  }

  Widget _buildListTile(
      BuildContext context,
      Versement versement,
      NumberFormat versementCurrencyFormat,
      Color? statusColor,
      bool isNegative) {
    return ListTile(
      onTap: () => onVersementTap(versement),
      title: Text(
        versement.reference ??
            AppLocalizations.of(context).translate('without_reference'),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        versement.createdAt != null
            ? DateFormat('dd/MM/yyyy').format(versement.createdAt!)
            : AppLocalizations.of(context).translate('unknown_date'),
        style: const TextStyle(fontSize: 16),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                versementCurrencyFormat.format(versement.montantVerser),
                style: const TextStyle(fontSize: 16, color: Colors.blue),
              ),
              Text(
                versementCurrencyFormat.format(versement.montantRestant),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Icon(
            isNegative ? Icons.arrow_downward : Icons.arrow_upward,
            color: statusColor,
            size: 20,
          ),
        ],
      ),
    );
  }
}
