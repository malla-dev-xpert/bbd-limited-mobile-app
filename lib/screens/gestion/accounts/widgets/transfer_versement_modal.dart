import 'package:flutter/material.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/core/services/partner_notification_service.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

class TransferVersementModal extends StatefulWidget {
  final Versement versement;
  final int currentPartnerId;
  final VoidCallback? onTransferSuccess;

  const TransferVersementModal({
    super.key,
    required this.versement,
    required this.currentPartnerId,
    this.onTransferSuccess,
  });

  @override
  State<TransferVersementModal> createState() => _TransferVersementModalState();
}

class _TransferVersementModalState extends State<TransferVersementModal> {
  final VersementServices _versementServices = VersementServices();
  final PartnerServices _partnerServices = PartnerServices();
  final PartnerNotificationService _partnerNotificationService =
      PartnerNotificationService();

  List<Partner> _partners = [];
  Partner? _selectedPartner;
  bool _isLoading = true;
  bool _isTransferring = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    try {
      final partners = await _partnerServices.findCustomers(page: 0);
      // Exclure le partenaire actuel de la liste
      final filteredPartners = partners
          .where((partner) => partner.id != widget.currentPartnerId)
          .toList();

      setState(() {
        _partners = filteredPartners;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            AppLocalizations.of(context).translate('error_loading_partners');
        _isLoading = false;
      });
    }
  }

  Future<void> _transferVersement() async {
    if (_selectedPartner == null) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context)
            .translate('please_select_destination_client'),
      );
      return;
    }

    setState(() {
      _isTransferring = true;
    });

    try {
      final result = await _versementServices.transferVersement(
        versementId: widget.versement.id!,
        oldPartnerId: widget.currentPartnerId,
        newPartnerId: _selectedPartner!.id,
      );

      if (result == "SUCCESS") {
        showSuccessTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('versement_transferred_successfully'),
        );

        // Notifier la mise à jour du partenaire de destination
        if (_selectedPartner != null) {
          _partnerNotificationService.notifyPartnerUpdate(_selectedPartner!);
        }

        if (widget.onTransferSuccess != null) {
          widget.onTransferSuccess!();
        }

        Navigator.of(context).pop(true);
      } else if (result == "WRONG_PARTNER") {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('cannot_transfer_wrong_partner'),
        );
      } else if (result == "SAME_PARTNER") {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('cannot_transfer_same_client'),
        );
      } else if (result == "IMPOSSIBLE_TRANSFERT") {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('cannot_transfer_operations_done'),
        );
      } else if (result == "BALANCE_INSUFFISANT") {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('cannot_transfer_insufficient_balance'),
        );
      } else if (result == "UNKNOWN_ERROR") {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('transfer_unknown_error'),
        );
      } else if (result == "ERROR") {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('transfer_failed'),
        );
      } else {
        // Message d'erreur spécifique du backend
        showErrorTopSnackBar(
          context,
          result,
        );
      }
    } catch (e) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context)
            .translate('transfer_error')
            .replaceAll('{error}', e.toString()),
      );
    } finally {
      setState(() {
        _isTransferring = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.swap_horiz,
                  color: Colors.blue[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)
                          .translate('transfer_versement'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)
                          .translate('select_destination_client'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Informations du versement
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('versement_details'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppLocalizations.of(context).translate('reference')}: ${widget.versement.reference ?? 'N/A'}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppLocalizations.of(context).translate('amount')}: ${widget.versement.montantVerser?.toStringAsFixed(2) ?? '0.00'} ${widget.versement.deviseCode ?? 'CNY'}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sélection du client de destination
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPartners,
                    child:
                        Text(AppLocalizations.of(context).translate('retry')),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)
                      .translate('select_destination_client'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                DropDownCustom<Partner>(
                  items: _partners,
                  selectedItem: _selectedPartner,
                  onChanged: (partner) {
                    setState(() {
                      _selectedPartner = partner;
                    });
                  },
                  itemToString: (partner) =>
                      '${partner.firstName} ${partner.lastName} | ${partner.phoneNumber}',
                  hintText:
                      AppLocalizations.of(context).translate('select_client'),
                  prefixIcon: Icons.person,
                ),
              ],
            ),

          const SizedBox(height: 32),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isTransferring
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context).translate('cancel')),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: confirmationButton(
                  isLoading: _isTransferring,
                  onPressed:
                      _selectedPartner == null ? () {} : _transferVersement,
                  label: AppLocalizations.of(context).translate('transfer'),
                  icon: Icons.swap_horiz,
                  subLabel:
                      AppLocalizations.of(context).translate('transferring'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
