import 'package:bbd_limited/core/enums/status.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/ion.dart';
import 'package:iconify_flutter/icons/ph.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

enum ExpeditionStatusFilter { all, delivered, inProgress, pending }

class PackageListItem extends StatelessWidget {
  final Packages packages;
  final VoidCallback onTap;

  // Constants for styling
  static const double _borderRadius = 20.0;
  static const double _padding = 20.0;
  static const double _iconSize = 17.0;
  static const double _spacing = 10.0;
  static const double _infoTextSize = 14.0;

  const PackageListItem({
    super.key,
    required this.packages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeColors = _getTypeColors(context);
    final iconData = _getExpeditionIcon();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_borderRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(_padding),
        margin: const EdgeInsets.symmetric(vertical: _spacing),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeIcon(typeColors, iconData),
            const SizedBox(width: _spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReferenceText(context),
                  _buildExpeditionDetails(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(_TypeColors statusColors, String iconData) {
    return Container(
      padding: const EdgeInsets.all(_spacing),
      decoration: BoxDecoration(
        color: statusColors.backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Iconify(iconData, color: statusColors.iconColor, size: _iconSize),
    );
  }

  Widget _buildReferenceText(BuildContext context) {
    final statusInfo = _getStatusInfo(context, packages.status?.name);

    return Row(
      children: [
        Text(
          packages.ref ??
              AppLocalizations.of(context).translate('package_no_reference'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: _spacing),
        const Text("|"),
        const SizedBox(width: _spacing),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: _spacing,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: statusInfo.backgroundColor,
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          child: Text(
            statusInfo.displayText,
            style: TextStyle(
              color: statusInfo.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpeditionDetails(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        const SizedBox(height: 5),
        _buildInfoText(
          "${AppLocalizations.of(context).translate('package_client_label')} : ${packages.clientName ?? AppLocalizations.of(context).translate('package_client_unspecified')} ${packages.clientPhone != null ? '| ${packages.clientPhone}' : ''}",
          maxLines: 1,
        ),
        _buildInfoText(
          packages.expeditionType?.toLowerCase() == "avion"
              ? "${AppLocalizations.of(context).translate('package_weight_label')} : ${packages.weight ?? 0} ${AppLocalizations.of(context).translate('kg')}"
              : "${AppLocalizations.of(context).translate('package_cbn_label')} : ${packages.cbn ?? 0} ${AppLocalizations.of(context).translate('m3')}",
        ),
        _buildInfoText(
          "${AppLocalizations.of(context).translate('package_destination_label')} : ${packages.destinationCountry ?? AppLocalizations.of(context).translate('package_destination_unspecified')}",
        ),
        _buildInfoText(
            "${AppLocalizations.of(context).translate('package_cartons_count')} : ${packages.itemQuantity ?? 0}"),
      ],
    );
  }

  Widget _buildInfoText(String text, {int maxLines = 2}) {
    // Diviser le texte en deux points pour séparer l’étiquette et la valeur
    final parts = text.split(':');
    if (parts.length != 2) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          fontSize: _infoTextSize,
        ),
      );
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: '${parts[0]}: ',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
              fontSize: _infoTextSize,
            ),
          ),
          TextSpan(
            text: parts[1],
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontSize: _infoTextSize,
            ),
          ),
        ],
      ),
    );
  }

  String _getExpeditionIcon() {
    return packages.expeditionType?.toLowerCase() == 'avion'
        ? Ph.airplane_tilt_fill
        : Ion.boat_sharp;
  }

  _TypeColors _getTypeColors(BuildContext context) {
    switch (packages.expeditionType?.toLowerCase()) {
      case "avion":
        return _TypeColors(
          backgroundColor: Colors.amber[50]!,
          iconColor: Colors.amber,
        );
      case "bateau":
        return _TypeColors(
          backgroundColor: Colors.deepPurple[50]!,
          iconColor: Colors.deepPurple,
        );
      default:
        return _TypeColors(
          backgroundColor: Colors.blue[50]!,
          iconColor: Colors.blue[400]!,
        );
    }
  }

  _StatusInfo _getStatusInfo(BuildContext context, String? status) {
    switch (packages.status) {
      case Status.DELIVERED:
        return _StatusInfo(
          displayText:
              AppLocalizations.of(context).translate('package_status_arrived'),
          backgroundColor: Colors.lightGreen[50]!,
          textColor: Colors.lightGreen[700]!,
        );
      case Status.RECEIVED:
        return _StatusInfo(
          displayText: AppLocalizations.of(context)
              .translate('package_status_delivered'),
          backgroundColor: Colors.green[50]!,
          textColor: Colors.green[700]!,
        );
      case Status.PENDING:
        return _StatusInfo(
          displayText:
              AppLocalizations.of(context).translate('package_status_pending'),
          backgroundColor: Colors.orange[50]!,
          textColor: Colors.orange[700]!,
        );
      case Status.DELETE:
        return _StatusInfo(
          displayText: AppLocalizations.of(context)
              .translate('package_status_cancelled'),
          backgroundColor: Colors.red[50]!,
          textColor: Colors.red[700]!,
        );
      case Status.INPROGRESS:
        return _StatusInfo(
          displayText: AppLocalizations.of(context)
              .translate('package_status_in_transit'),
          backgroundColor: Colors.purple[50]!,
          textColor: Colors.purple[700]!,
        );
      default:
        return _StatusInfo(
          displayText:
              AppLocalizations.of(context).translate('package_status_unknown'),
          backgroundColor: Colors.grey[300]!,
          textColor: Colors.grey[700]!,
        );
    }
  }
}

class _TypeColors {
  final Color? backgroundColor;
  final Color? iconColor;

  const _TypeColors({required this.backgroundColor, required this.iconColor});
}

class _StatusInfo {
  final String displayText;
  final Color backgroundColor;
  final Color textColor;

  const _StatusInfo({
    required this.displayText,
    required this.backgroundColor,
    required this.textColor,
  });
}
