import 'dart:developer';

import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/buildDetailRow.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/buildNoteField.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/achats/update_achat_dto.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/routes.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:intl/intl.dart';
import 'widgets/cash_withdrawal_form.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/models/cashWithdrawal.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/devises.dart';
import 'package:bbd_limited/core/services/devises_service.dart';
import 'package:bbd_limited/utils/invoice_service.dart';
import 'package:printing/printing.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/print/print_localizations.dart';
import 'package:bbd_limited/core/print/print_language.dart';
import 'package:bbd_limited/components/print/print_config_page.dart';
import 'package:bbd_limited/models/invoice_options.dart';
import 'package:bbd_limited/screens/gestion/sales/achat_details_sheet.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/components/confirm_btn.dart';

class VersementDetailScreen extends StatefulWidget {
  final Versement versement;
  final VoidCallback? onVersementUpdated;

  const VersementDetailScreen({
    Key? key,
    required this.versement,
    this.onVersementUpdated,
  }) : super(key: key);

  @override
  State<VersementDetailScreen> createState() => _VersementDetailScreenState();
}

class _VersementDetailScreenState extends State<VersementDetailScreen> {
  final DeviseServices _deviseServices = DeviseServices();
  final AchatServices _achatServices = AchatServices();
  bool isLoading = false;
  bool _isInfoExpanded = true;
  bool _isArticlesExpanded = false;
  bool _isWithdrawalsExpanded = false;
  late NumberFormat currencyFormat;
  bool showOperationButtons = false;
  late List<Achat> _achats = [];

  // Options de facturation configurables
  InvoiceOptions _invoiceOptions = const InvoiceOptions();

  @override
  void initState() {
    super.initState();
    currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: widget.versement.deviseCode ?? 'CNY',
    );
    _achats = List.from(widget.versement.achats ?? []);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VersementDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.versement != widget.versement) {
      _achats = List.from(widget.versement.achats ?? []);
    }
  }

  Future<void> _loadVersementData() async {
    try {
      // Appeler l'API pour récupérer les données mises à jour du versement
      widget.onVersementUpdated?.call();
    } catch (e) {
      log('Erreur lors du rechargement du versement: $e');
    }
  }

  void _updateInvoiceOptions(InvoiceOptions newOptions) {
    setState(() {
      _invoiceOptions = newOptions;
    });
  }

  // Ajout d'une fonction utilitaire pour calculer les totaux de factures
  Map<String, int> _getFactureStats(Achat achat) {
    // Map<numeroFacture, List<article>>
    final Map<String, List<dynamic>> factureMap = {};
    for (final item in (achat.items ?? [])) {
      final facture = (item.invoiceNumber ?? '').trim();
      if (facture.isEmpty) continue;
      factureMap.putIfAbsent(facture, () => []).add(item);
    }
    int totalFactures = factureMap.length;
    int totalFacturesPayees = factureMap.values
        .where((articles) => articles.every((a) => a.status == Status.RECEIVED))
        .length;
    return {
      'total': totalFactures,
      'payees': totalFacturesPayees,
    };
  }

  // Méthode pour obtenir les informations sur les fournisseurs
  String _getSuppliersInfo(Achat achat) {
    if (achat.items == null || achat.items!.isEmpty) {
      return 'Aucun';
    }

    final suppliers = <String>{};
    for (var item in achat.items!) {
      if (item.supplierName != null && item.supplierName!.isNotEmpty) {
        suppliers.add(item.supplierName!);
      }
    }

    if (suppliers.isEmpty) {
      return 'Aucun';
    }

    if (suppliers.length == 1) {
      return 'Même fournisseur';
    } else {
      return '${suppliers.length}';
    }
  }

  // Méthode pour construire une ligne d'information sur les articles
  Widget _buildArticleInfoRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showAchatDetails(BuildContext context, Achat achat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AchatDetailsSheet(achat: achat),
    );
  }

  void _showEditDateDialog(Achat achat) {
    DateTime selectedDate = achat.createdAt ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context).translate('edit_date')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppLocalizations.of(context).translate('purchase_number')} : ${achat.id ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  selectedDate = picked;
                  (context as Element).markNeedsBuild();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          confirmationButton(
            isLoading: isLoading,
            onPressed: () => _updateAchatDate(achat, selectedDate),
            label: AppLocalizations.of(context).translate('save'),
            icon: Icons.save,
            subLabel: AppLocalizations.of(context).translate('saving'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAchatDate(Achat achat, DateTime newDate) async {
    if (achat.id == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final user = await AuthService().getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context,
            AppLocalizations.of(context).translate('user_not_connected'));
        return;
      }

      final dto = UpdateAchatDto(createdAt: newDate);
      final result = await _achatServices.updateAchat(
        achatId: achat.id!,
        userId: user.id,
        dto: dto,
      );

      if (result.isSuccess) {
        setState(() {
          // Mettre à jour la date dans la liste locale
          for (int i = 0; i < _achats.length; i++) {
            if (_achats[i].id == achat.id) {
              _achats[i] = _achats[i].copyWith(createdAt: newDate);
            }
          }
        });
        showSuccessTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('date_updated_successfully'));
        Navigator.pop(context);
        widget.onVersementUpdated?.call();
      } else {
        showErrorTopSnackBar(
            context,
            result.errorMessage ??
                AppLocalizations.of(context).translate('error_updating_date'));
      }
    } catch (e) {
      showErrorTopSnackBar(context,
          AppLocalizations.of(context).translate('error_updating_date'));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildAchatList() {
    if (_achats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "Aucun achat trouvé pour ce versement.",
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _achats.length,
      itemBuilder: (context, index) {
        final achat = _achats[index];
        final factureStats = _getFactureStats(achat);
        return Slidable(
          key: ValueKey('achat_${achat.id ?? index}'),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (_) => _showEditDateDialog(achat),
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                icon: Icons.edit_calendar,
                label: AppLocalizations.of(context).translate('edit_date'),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showAchatDetails(context, achat),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppLocalizations.of(context).translate('purchase_number')} : ${achat.id ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.grey[700]!,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(
                                          achat.createdAt ?? DateTime.now()),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700]!,
                                      ),
                                    ),
                                  ],
                                ),
                                if (achat.isDebt == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7F78AF)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFF7F78AF)),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)
                                            .translate('purchase_history_debt'),
                                        style: const TextStyle(
                                          color: Color(0xFF7F78AF),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Image.asset(
                            achat.status == Status.COMPLETED
                                ? 'assets/images/delivery.png'
                                : 'assets/images/no-delivery.png',
                            width: 44,
                            height: 44,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.grey[700]!,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (achat.client != null && achat.client!.isNotEmpty)
                                  ? achat.client!
                                  : (achat.isDebt == true &&
                                          achat.clientId != null)
                                      ? '${AppLocalizations.of(context).translate('client')} #${achat.clientId}'
                                      : AppLocalizations.of(context)
                                          .translate('not_available'),
                              style: TextStyle(
                                color: Colors.grey[700]!,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (achat.clientPhone != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: Colors.grey[700]!,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              achat.clientPhone!,
                              style: TextStyle(
                                color: Colors.grey[700]!,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Informations sur les articles
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          children: [
                            _buildArticleInfoRow(
                              Icons.inventory_2,
                              'Total articles',
                              '${achat.items?.length ?? 0}',
                              Colors.blue[700]!,
                            ),
                            const SizedBox(height: 12),
                            _buildArticleInfoRow(
                              Icons.check_circle,
                              'Factures payées',
                              '${factureStats['payees']}/${factureStats['total']}',
                              Colors.green[700]!,
                            ),
                            const SizedBox(height: 12),
                            _buildArticleInfoRow(
                              Icons.business,
                              'Fournisseurs',
                              _getSuppliersInfo(achat),
                              Colors.orange[700]!,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Montant total
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1E49).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF1A1E49).withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Montant total : ',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                currencyFormat.format(achat.montantTotal ?? 0),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1E49),
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsibleInfo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isInfoExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isInfoExpanded = expanded;
            });
          },
          title: const Text(
            "Informations du versement",
            style: TextStyle(
              color: Color(0xFF1A1E49),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildDetailRow("Référence", widget.versement.reference),
                  buildDetailRow("Type", widget.versement.type),
                  buildNoteField(widget.versement.note),
                  buildDetailRow("Client", widget.versement.partnerName),
                  if (widget.versement.partnerPhone != null)
                    buildDetailRow(
                        "Téléphone", "${widget.versement.partnerPhone}"),
                  buildDetailRow(
                    "Commissionnaire",
                    widget.versement.commissionnaireName ?? 'N/V',
                  ),
                  buildDetailRow(
                    "Téléphone",
                    "${widget.versement.commissionnairePhone}",
                  ),
                  buildDetailRow(
                    "Montant versé",
                    currencyFormat.format(widget.versement.montantVerser),
                  ),
                  buildDetailRow(
                    "Montant restante",
                    currencyFormat.format(widget.versement.montantRestant),
                  ),
                  buildDetailRow(
                    "Date de versement",
                    DateFormat('dd/MM/yyyy')
                        .format(widget.versement.createdAt!),
                  ),
                  buildDetailRow(
                    "Total des achats",
                    _achats.expand((a) => a.items ?? []).length.toString(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleAchats() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isArticlesExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isArticlesExpanded = expanded;
            });
          },
          title: const Text(
            "Liste des achats",
            style: TextStyle(
              color: Color(0xFF1A1E49),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildAchatList(),
            ),
          ],
        ),
      ),
    );
  }

  void _handleWithdrawal() {
    showDialog(
      context: context,
      builder: (context) => CashWithdrawalForm(
        partnerId: widget.versement.partnerId!,
        versementId: widget.versement.id!,
        deviseCode: widget.versement.deviseCode ?? 'CNY',
        onSubmit: (montant, note) async {
          if (widget.versement.deviseId == null) {
            showErrorTopSnackBar(
                context, "Devise non trouvée pour ce versement");
            return;
          }
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
          try {
            setState(() {
              isLoading = true;
            });
            final user = await AuthService().getUserInfo();
            if (user == null) {
              Navigator.of(context).pop();
              showErrorTopSnackBar(context, "Utilisateur non connecté");
              return;
            }
            final result = await VersementServices().createRetraitArgent(
              partnerId: widget.versement.partnerId!,
              versementId: widget.versement.id!,
              deviseId: widget.versement.deviseId!,
              montant: montant,
              note: note,
              userId: user.id,
            );

            if (result == 'SUCCESS') {
              Navigator.of(context).pop();
              showSuccessTopSnackBar(context, "Retrait effectué avec succès !");
              // Ajout dynamique du retrait à la liste
              setState(() {
                widget.versement.cashWithdrawalDtoList ??= [];
                widget.versement.cashWithdrawalDtoList!.add(
                  CashWithdrawal(
                    id: null, // L'id réel n'est pas connu
                    montant: montant,
                    dateRetrait: DateTime.now(),
                    note: note,
                    partner: Partner(
                      id: widget.versement.partnerId ?? 0,
                      firstName:
                          widget.versement.partnerName?.split(' ').first ?? '',
                      lastName: widget.versement.partnerName
                              ?.split(' ')
                              .skip(1)
                              .join(' ') ??
                          '',
                      phoneNumber: widget.versement.partnerPhone ?? '',
                      email: '',
                      country: '',
                      adresse: '',
                      accountType: widget.versement.partnerAccountType ?? '',
                    ),
                    versement: widget.versement,
                    devise: Devise(
                      id: widget.versement.deviseId,
                      name: widget.versement.deviseCode ?? '',
                      code: widget.versement.deviseCode ?? '',
                    ),
                    user: user,
                    status: Status.CREATE,
                  ),
                );
              });
              widget.onVersementUpdated?.call();
            } else if (result == "INSUFFICIENT_FUNDS") {
              showErrorTopSnackBar(
                  context, "Montant supérieur au montant restant du versement");
            }
          } catch (e) {
            Navigator.of(context).pop();
            showErrorTopSnackBar(context, e.toString());
          } finally {
            setState(() {
              isLoading = false;
            });
          }
        },
      ),
    );
  }

  Widget _buildCollapsibleWithdrawals() {
    final withdrawals = widget.versement.cashWithdrawalDtoList ?? [];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isWithdrawalsExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isWithdrawalsExpanded = expanded;
            });
          },
          title: const Text(
            "Liste des retraits d'achat",
            style: TextStyle(
              color: Color(0xFF1A1E49),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: withdrawals.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucun retrait effectué pour ce versement.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: withdrawals.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final w = withdrawals[index];
                        final currencyFormat = NumberFormat.currency(
                          locale: 'fr_FR',
                          symbol: w.devise.code,
                        );
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.money_outlined,
                                      color: Colors.orange[700], size: 28),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      currencyFormat.format(w.montant),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Color(0xFF1A1E49),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: w.status == Status.CREATE
                                          ? Colors.green[100]
                                          : Colors.orange[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          w.status == Status.CREATE
                                              ? Icons.check_circle
                                              : Icons.timelapse,
                                          color: w.status == Status.CREATE
                                              ? Colors.green[700]
                                              : Colors.orange[700],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          w.status == Status.CREATE
                                              ? 'Validé'
                                              : 'En attente',
                                          style: TextStyle(
                                            color: w.status == Status.CREATE
                                                ? Colors.green[700]
                                                : Colors.orange[700],
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.person,
                                          size: 18, color: Color(0xFF7F78AF)),
                                      const SizedBox(width: 4),
                                      Text(
                                        (w.userName != null &&
                                                w.userName!.trim().isNotEmpty)
                                            ? w.userName!
                                            : ((w.user.firstName ?? '')
                                                        .trim()
                                                        .isNotEmpty ||
                                                    (w.user.lastName ?? '')
                                                        .trim()
                                                        .isNotEmpty)
                                                ? '${w.user.firstName ?? ''} ${w.user.lastName ?? ''}'
                                                    .trim()
                                                : w.user.username,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 16, color: Colors.blueGrey),
                                      const SizedBox(width: 4),
                                      Text(
                                        w.dateRetrait != null
                                            ? DateFormat('dd/MM/yyyy – HH:mm')
                                                .format(DateTime.parse(
                                                    w.dateRetrait.toString()))
                                            : 'Date inconnue',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (w.note != null &&
                                  w.note!.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.sticky_note_2_outlined,
                                        size: 16, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        w.note!,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Remettre la méthode _handlePurchase ici :
  void _handlePurchase() async {
    setState(() {
      isLoading = true;
    });
    if (widget.versement.partnerId == null || widget.versement.id == null) {
      showErrorTopSnackBar(
        context,
        "Informations du versement incomplètes",
      );
      return;
    }

    // Récupérer la devise complète si deviseId est disponible
    Devise? devise;
    if (widget.versement.deviseId != null) {
      try {
        final allDevises = await _deviseServices.findAllDevises(page: 0);
        devise = allDevises.firstWhere(
          (d) => d.id == widget.versement.deviseId,
          orElse: () => Devise(
            id: widget.versement.deviseId,
            name: widget.versement.deviseCode ?? 'CNY',
            code: widget.versement.deviseCode ?? 'CNY',
          ),
        );
      } catch (e) {
        // En cas d'erreur, créer une devise basique avec les informations disponibles
        devise = Devise(
          id: widget.versement.deviseId,
          name: widget.versement.deviseCode ?? 'CNY',
          code: widget.versement.deviseCode ?? 'CNY',
        );
      }
    }

    Navigator.pushNamed(
      context,
      Routes.purchase,
      arguments: {
        'clientId': widget.versement.partnerId!,
        'versementId': widget.versement.id!,
        'invoiceNumber': widget.versement.reference ?? '',
        'devise': devise,
        'tauxChange': devise?.rate,
        'onPurchaseComplete': (achat) {
          // Recharger les données du versement pour obtenir la liste mise à jour des achats
          _loadVersementData();
          widget.onVersementUpdated?.call();
        },
      },
    );
    setState(() {
      isLoading = false;
    });
  }

  void _showPrintDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrintConfigPage(
          title: AppLocalizations.of(context)
              .translate('billing_options_configuration'),
          previewButtonLabel: AppLocalizations.of(context)
              .translate('purchase_history_preview_pdf'),
          initialOptions: _invoiceOptions,
          currencySymbol: widget.versement.deviseCode ?? '¥',
          onOptionsChanged: _updateInvoiceOptions,
          onPreview: (result) =>
              _showPdfPreviewDialog(context, result.printLanguage),
          printOptionsTitle: AppLocalizations.of(context)
              .translate('purchase_history_invoice_options'),
          billingOptionsTitle:
              AppLocalizations.of(context).translate('billing_options'),
          appliedOptionsLabel: AppLocalizations.of(context)
              .translate('currently_applied_options'),
          showBillingOptions: false,
        ),
      ),
    );
  }

  Future<void> _showPdfPreviewDialog(
      BuildContext context, PrintLanguage printLanguage) async {
    final printLocalizations = await PrintLocalizations.create(printLanguage);
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.6,
          child: PdfPreview(
            build: (format) => InvoiceService.buildVersementPdfBytes(
                widget.versement,
                _achats,
                widget.versement.cashWithdrawalDtoList ?? [],
                printLocalizations,
                invoiceOptions: _invoiceOptions),
            pdfFileName: 'recu_${widget.versement.reference ?? ""}.pdf',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A1E49),
        title: const Text(
          "Détails du versement",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: () => _showPrintDialog(context),
            icon: const Icon(
              Icons.print,
              color: Colors.white,
            ),
            label: Text(
              AppLocalizations.of(context).translate('print'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCollapsibleInfo(),
                    const SizedBox(height: 16),
                    _buildCollapsibleAchats(),
                    const SizedBox(height: 16),
                    _buildCollapsibleWithdrawals(),
                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
              ),
            ),
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: offsetAnimation,
                  child: child,
                ),
              );
            },
            child: showOperationButtons
                ? Padding(
                    key: const ValueKey('operationButtons'),
                    padding: const EdgeInsets.only(bottom: 90.0, right: 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7F78AF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              showOperationButtons = false;
                            });
                            _handlePurchase();
                          },
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: const Text('Effectuer un achat'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              showOperationButtons = false;
                            });
                            _handleWithdrawal();
                          },
                          icon: const Icon(Icons.money_off_csred_outlined),
                          label: const Text("Retrait d'argent"),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          FloatingActionButton.extended(
            onPressed: () {
              setState(() {
                showOperationButtons = !showOperationButtons;
              });
            },
            backgroundColor: const Color(0xFF1A1E49),
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            label: const Text(
              'Effectuer une opération',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
