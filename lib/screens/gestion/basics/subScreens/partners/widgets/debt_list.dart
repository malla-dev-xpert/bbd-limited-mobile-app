import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/models/achats/update_achat_dto.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:bbd_limited/components/confirm_btn.dart';

class DebtListWidget extends StatefulWidget {
  final List<Achat>? debts;
  final Future<void> Function() onRefresh;
  final void Function(BuildContext, Achat) onDebtTap;

  const DebtListWidget({
    Key? key,
    required this.debts,
    required this.onRefresh,
    required this.onDebtTap,
  }) : super(key: key);

  @override
  State<DebtListWidget> createState() => _DebtListWidgetState();
}

class _DebtListWidgetState extends State<DebtListWidget> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (widget.debts == null || widget.debts!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).translate('no_debts_found'),
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: widget.debts?.length ?? 0,
        itemBuilder: (context, index) {
          final achat = widget.debts![index];
          return Slidable(
            key: ValueKey('debt_${achat.id ?? index}'),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) => _showEditDateDialog(context, achat),
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
                  onTap: () => widget.onDebtTap(context, achat),
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
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: const Color(0xFF7F78AF)),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)
                                              .translate(
                                                  'purchase_history_debt'),
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
                                (achat.client != null &&
                                        achat.client!.isNotEmpty)
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
                                AppLocalizations.of(context)
                                    .translate('total_items'),
                                '${achat.items?.length ?? 0}',
                                Colors.blue[700]!,
                              ),
                              const SizedBox(height: 12),
                              _buildArticleInfoRow(
                                Icons.check_circle,
                                AppLocalizations.of(context)
                                    .translate('delivered_items'),
                                '${_getDeliveredItemsCount(achat)}/${_getTotalInvoicesCount(achat)}',
                                Colors.green[700]!,
                              ),
                              const SizedBox(height: 12),
                              _buildArticleInfoRow(
                                Icons.business,
                                AppLocalizations.of(context)
                                    .translate('suppliers'),
                                _getSuppliersInfo(achat, context),
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
                                color:
                                    const Color(0xFF1A1E49).withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .translate('purchase_history_total_amount'),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${_formatAmount(achat.montantTotal)} ¥',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1E49),
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
      ),
    );
  }

  String _formatAmount(double? amount) {
    if (amount == null) return "0,00";
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]} ',
        )
        .replaceAll('.', ',');
  }

  // Méthode pour compter les articles livrés (par numéro de facture)
  int _getDeliveredItemsCount(Achat achat) {
    if (achat.items == null) return 0;

    final deliveredInvoices = <String>{};
    for (var item in achat.items!) {
      if (item.status == Status.RECEIVED &&
          item.invoiceNumber != null &&
          item.invoiceNumber!.isNotEmpty) {
        deliveredInvoices.add(item.invoiceNumber!);
      }
    }
    return deliveredInvoices.length;
  }

  // Méthode pour compter le total des factures
  int _getTotalInvoicesCount(Achat achat) {
    if (achat.items == null) return 0;

    final allInvoices = <String>{};
    for (var item in achat.items!) {
      if (item.invoiceNumber != null && item.invoiceNumber!.isNotEmpty) {
        allInvoices.add(item.invoiceNumber!);
      }
    }
    return allInvoices.length;
  }

  // Méthode pour obtenir les informations sur les fournisseurs
  String _getSuppliersInfo(Achat achat, BuildContext context) {
    if (achat.items == null || achat.items!.isEmpty) {
      return AppLocalizations.of(context).translate('none');
    }

    final suppliers = <String>{};
    for (var item in achat.items!) {
      if (item.supplierName != null && item.supplierName!.isNotEmpty) {
        suppliers.add(item.supplierName!);
      }
    }

    if (suppliers.isEmpty) {
      return AppLocalizations.of(context).translate('none');
    }

    if (suppliers.length == 1) {
      return AppLocalizations.of(context).translate('same_supplier');
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

  void _showEditDateDialog(BuildContext context, Achat achat) {
    DateTime selectedDate = achat.createdAt ?? DateTime.now();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                    setState(() {});
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
                onPressed: () =>
                    _updateAchatDate(context, achat, selectedDate, setState),
                label: AppLocalizations.of(context).translate('save'),
                icon: Icons.save,
                subLabel: AppLocalizations.of(context).translate('saving')),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAchatDate(BuildContext context, Achat achat,
      DateTime newDate, StateSetter setState) async {
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

      final achatServices = AchatServices();
      final dto = UpdateAchatDto(createdAt: newDate);
      final result = await achatServices.updateAchat(
        achatId: achat.id!,
        userId: user.id,
        dto: dto,
      );

      if (result.isSuccess) {
        showSuccessTopSnackBar(
            context,
            AppLocalizations.of(context)
                .translate('date_updated_successfully'));
        Navigator.pop(context);
        widget.onRefresh();
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
}
