import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/partner_notification_service.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

/// Écran de transfert de versement (remplace l’ancien bottom sheet).
/// Suit l’architecture des écrans (Scaffold + AppBar) et utilise [AppTextSize] pour le texte responsive.
class TransferVersementScreen extends StatefulWidget {
  final Versement versement;
  final int currentPartnerId;
  final VoidCallback? onTransferSuccess;

  const TransferVersementScreen({
    super.key,
    required this.versement,
    required this.currentPartnerId,
    this.onTransferSuccess,
  });

  @override
  State<TransferVersementScreen> createState() => _TransferVersementScreenState();
}

class _TransferVersementScreenState extends State<TransferVersementScreen> {
  final VersementServices _versementServices = VersementServices();
  final PartnerServices _partnerServices = PartnerServices();
  final AuthService _authService = AuthService();
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

    final user = await _authService.getUserInfo();
    if (user == null) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('user_not_connected'),
      );
      return;
    }

    setState(() {
      _isTransferring = true;
    });

    try {
      final result = await _versementServices.transferVersement(
        versementId: widget.versement.id!,
        userId: user.id,
        oldPartnerId: widget.currentPartnerId,
        newPartnerId: _selectedPartner!.id,
      );

      if (result == "SUCCESS") {
        showSuccessTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('versement_transferred_successfully'),
        );

        if (_selectedPartner != null) {
          _partnerNotificationService.notifyPartnerUpdate(_selectedPartner!);
        }

        widget.onTransferSuccess?.call();
        if (mounted) Navigator.of(context).pop(true);
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
        showErrorTopSnackBar(context, result);
      }
    } catch (e) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context)
            .translate('transfer_error')
            .replaceAll('{error}', e.toString()),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTransferring = false;
        });
      }
    }
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextSize.bodyStyle(context,
                  color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextSize.subtitleStyle(context,
                  color: Colors.grey[900], fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.versement;
    final devise = v.deviseCode ?? 'CNY';
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A1E49),
        title: Text(
          AppLocalizations.of(context).translate('transfer_versement'),
          style: AppTextSize.titleStyle(context).copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête visuel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.swap_horiz,
                        color: Colors.blue[700],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)
                            .translate('select_destination_client'),
                        style: AppTextSize.subtitleStyle(context,
                            color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Détails du versement — carte avec plus d'infos
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long,
                            size: 22, color: Colors.blue[700]),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalizations.of(context)
                              .translate('versement_details'),
                          style: AppTextSize.subtitleStyle(context,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1E49)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      context,
                      label: AppLocalizations.of(context).translate('reference'),
                      value: v.reference ?? 'N/A',
                    ),
                    _buildDetailRow(
                      context,
                      label: AppLocalizations.of(context).translate('amount'),
                      value:
                          '${(v.montantVerser ?? 0).toStringAsFixed(2)} $devise',
                    ),
                    if (v.montantRestant != null)
                      _buildDetailRow(
                        context,
                        label: AppLocalizations.of(context)
                            .translate('remaining_amount'),
                        value:
                            '${(v.montantRestant ?? 0).toStringAsFixed(2)} $devise',
                      ),
                    if (v.partnerName != null && v.partnerName!.isNotEmpty)
                      _buildDetailRow(
                        context,
                        label: AppLocalizations.of(context).translate('client'),
                        value: v.partnerName!,
                      ),
                    if (v.createdAt != null)
                      _buildDetailRow(
                        context,
                        label: AppLocalizations.of(context).translate('date'),
                        value: dateFormat.format(v.createdAt!),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Sélection du client de destination
              if (_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(
                      color: Colors.blue[700],
                    ),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[400], size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: AppTextSize.bodyStyle(context,
                              color: Colors.red[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        confirmationButton(
                          isLoading: false,
                          onPressed: _loadPartners,
                          label: AppLocalizations.of(context).translate('retry'),
                          icon: Icons.refresh,
                          subLabel: '',
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                            .translate('select_destination_client'),
                        style: AppTextSize.subtitleStyle(context,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1E49)),
                      ),
                      const SizedBox(height: 14),
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
                        hintText: AppLocalizations.of(context)
                            .translate('select_client'),
                        prefixIcon: Icons.person,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              // Boutons : même composant, même taille — Annuler gris, Transfert vert
              Row(
                children: [
                  Expanded(
                    child: confirmationButton(
                      isLoading: false,
                      onPressed: _isTransferring
                          ? () {}
                          : () => Navigator.of(context).pop(),
                      label: AppLocalizations.of(context).translate('cancel'),
                      icon: Icons.close,
                      subLabel: '',
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: confirmationButton(
                      isLoading: _isTransferring,
                      onPressed: _selectedPartner == null
                          ? () {}
                          : _transferVersement,
                      label:
                          AppLocalizations.of(context).translate('transfer'),
                      icon: Icons.swap_horiz,
                      subLabel: AppLocalizations.of(context)
                          .translate('transferring'),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
