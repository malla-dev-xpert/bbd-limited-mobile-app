import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/purchase_dialog.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:intl/intl.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'widgets/cash_withdrawal_form.dart';
import 'package:bbd_limited/core/services/versement_services.dart';
import 'package:bbd_limited/models/cashWithdrawal.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/models/devises.dart';
import 'package:bbd_limited/core/services/devises_service.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final AchatServices _achatServices = AchatServices();
  final DeviseServices _deviseServices = DeviseServices();
  String _searchQuery = '';
  bool isLoading = false;
  bool _isInfoExpanded = true;
  bool _isArticlesExpanded = false;
  bool _isWithdrawalsExpanded = false;
  late NumberFormat currencyFormat;
  final Set<String> _confirmedArticles = {};
  bool showOperationButtons = false;
  late List<Achat> _achats = [];
  // Ajout d'une map pour stocker la recherche par achat
  final Map<int, String> _searchQueries = {};

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
  void didUpdateWidget(covariant VersementDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.versement != widget.versement) {
      _achats = List.from(widget.versement.achats ?? []);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildDetailRow(String label, String? value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontSize: 15,
            ),
          ),
          Flexible(
            child: Text(
              value ?? '',
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF1A1E49),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1A1E49),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
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

  Widget _buildAchatList() {
    if (_achats.isEmpty) {
      return const Center(
        child: Text("Aucun achat trouvé pour ce versement."),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _achats.length,
      itemBuilder: (context, index) {
        final achat = _achats[index];
        final factureStats = _getFactureStats(achat);
        final achatId = achat.id ?? index;
        final searchQuery = _searchQueries[achatId] ?? '';
        final items = achat.items ?? [];
        final filteredItems = searchQuery.isEmpty
            ? items
            : items.where((ligne) {
                final desc = (ligne.description ?? '').toLowerCase();
                final invoice = (ligne.invoiceNumber ?? '').toLowerCase();
                final search = searchQuery.toLowerCase();
                return desc.contains(search) || invoice.contains(search);
              }).toList();
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Achat #${achat.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A1E49),
                      ),
                    ),
                  ),
                  if (achat.isDebt == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7F78AF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF7F78AF)),
                      ),
                      child: Text(
                        'Dette #${achat.id}',
                        style: TextStyle(
                          color: Color(0xFF7F78AF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Montant: ' +
                        currencyFormat.format(achat.montantTotal ?? 0),
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.receipt_long,
                          size: 16, color: Color(0xFF7F78AF)),
                      const SizedBox(width: 4),
                      Text(
                        'Factures: ${factureStats['payees']}/${factureStats['total']} payées',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF7F78AF)),
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher un article ou une facture...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32),
                        borderSide: const BorderSide(
                          color: Color(0xFF1A1E49),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQueries[achatId] = value;
                      });
                    },
                  ),
                ),
                if (filteredItems.isNotEmpty)
                  ...filteredItems
                      .map((ligne) => _buildAchatArticleCard(ligne, achat))
                      .toList()
                else
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                        "Aucun article pour cet achat ou cette recherche."),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchatArticleCard(dynamic ligne, Achat achat) {
    final isConfirmed = _confirmedArticles.contains(ligne.id?.toString());
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ligne.description ?? 'Article sans nom',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Modifier',
                onPressed: () => _showEditArticleDialog(ligne),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Supprimer',
                onPressed: () => _confirmDeleteArticle(ligne),
              ),
              if (!isConfirmed && ligne.status != Status.RECEIVED)
                ElevatedButton.icon(
                  onPressed: () => _confirmArticle(ligne.id?.toString() ?? ''),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(isLoading ? "Chargement..." : "Confirmer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1E49),
                    foregroundColor: Colors.white,
                  ),
                )
              else if (ligne.status == Status.RECEIVED)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[700],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reçu',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          _buildDetailItem('Quantité', '${ligne.quantity}'),
          const SizedBox(height: 4),
          _buildDetailItem('Fournisseur', ligne.supplierName ?? 'N/A'),
          if (ligne.supplierPhone != null) const SizedBox(height: 4),
          if (ligne.supplierPhone != null)
            _buildDetailItem('Téléphone', ligne.supplierPhone ?? 'N/A'),
          const SizedBox(height: 4),
          _buildDetailItem('Taux d\'achat', ligne.salesRate.toString()),
          const SizedBox(height: 4),
          _buildDetailItem(
            'Prix Unitaire',
            currencyFormat.format(ligne.unitPrice ?? 0),
          ),
          const SizedBox(height: 4),
          _buildDetailItem(
            'Total',
            currencyFormat.format(
              ligne.totalPrice ??
                  (ligne.quantity ?? 0) * (ligne.unitPrice ?? 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField(String? note) {
    if (note == null || note.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Note",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: const TextStyle(
              color: Color(0xFF1A1E49),
              fontSize: 14,
            ),
          ),
        ],
      ),
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
              fontSize: 16,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow("Référence", widget.versement.reference),
                  _buildDetailRow("Type", widget.versement.type),
                  _buildNoteField(widget.versement.note),
                  _buildDetailRow("Client", widget.versement.partnerName),
                  if (widget.versement.partnerPhone != null)
                    _buildDetailRow(
                        "Téléphone", "${widget.versement.partnerPhone}"),
                  _buildDetailRow(
                    "Commissionnaire",
                    widget.versement.commissionnaireName ?? 'N/V',
                  ),
                  _buildDetailRow(
                    "Téléphone",
                    "${widget.versement.commissionnairePhone}",
                  ),
                  _buildDetailRow(
                    "Montant versé",
                    currencyFormat.format(widget.versement.montantVerser),
                  ),
                  _buildDetailRow(
                    "Montant restante",
                    currencyFormat.format(widget.versement.montantRestant),
                  ),
                  _buildDetailRow(
                    "Date de versement",
                    DateFormat('dd/MM/yyyy')
                        .format(widget.versement.createdAt!),
                  ),
                  _buildDetailRow(
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

  Widget _buildCollapsibleArticles() {
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
              fontSize: 16,
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

  Future<void> _confirmArticle(String itemId) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final user = await AuthService().getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context, "Utilisateur non connecté");
        return;
      }
      final result = await _achatServices.confirmDelivery(
        itemIds: [int.parse(itemId)],
        userId: user.id,
      );

      if (result.isSuccess) {
        for (var achat in _achats) {
          for (var item in achat.items ?? []) {
            if (item.id?.toString() == itemId) {
              item.status = Status.RECEIVED;
              break;
            }
          }
        }

        setState(() {
          _confirmedArticles.add(itemId);
        });
        showSuccessTopSnackBar(context, "Article reçu avec succès");

        widget.onVersementUpdated?.call();
      } else {
        showErrorTopSnackBar(
            context, result.errorMessage ?? "Erreur lors de la confirmation");
      }
    } catch (e) {
      showErrorTopSnackBar(
          context, "Une erreur est survenue lors de la confirmation");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
              fontSize: 16,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: withdrawals.isEmpty
                  ? const Center(
                      child: Text(
                        "Aucun retrait effectué pour ce versement.",
                        style: TextStyle(fontSize: 15, color: Colors.grey),
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
                                            fontSize: 13,
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
                                                : (w.user.username ?? ''),
                                        style: const TextStyle(
                                            fontSize: 14,
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
                                            fontSize: 13,
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
                                            fontSize: 13,
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

  void _confirmDeleteArticle(dynamic ligne) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet article ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _deleteArticle(ligne);
              Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteArticle(dynamic ligne) async {
    setState(() {
      isLoading = true;
    });
    try {
      final user = await AuthService().getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(context, "Utilisateur non connecté");
        setState(() {
          isLoading = false;
        });
        return;
      }
      final itemServices = ItemServices();
      final result = await itemServices.deleteItem(
        ligne.id,
        user.id,
        widget.versement.partnerId!,
      );
      if (result == "DELETED") {
        setState(() {
          for (var achat in _achats) {
            achat.items?.remove(ligne);
          }
        });
        showSuccessTopSnackBar(context, "Article supprimé avec succès");
        widget.onVersementUpdated?.call();
      } else if (result == "ITEM_NOT_FOUND") {
        showErrorTopSnackBar(context, "Article non trouvé.");
      } else if (result == "CLIENT_NOT_FOUND_OR_MISMATCH") {
        showErrorTopSnackBar(context, "Client non trouvé ou ne correspond pas");
      } else if (result == "USER_NOT_FOUND") {
        showErrorTopSnackBar(context, "Utilisateur non trouvé.");
      } else {
        showErrorTopSnackBar(context, result?.toString() ?? "Erreur inconnue");
      }
    } catch (e) {
      showErrorTopSnackBar(context, "Erreur lors de la suppression : $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showEditArticleDialog(Items ligne) async {
    final descriptionController =
        TextEditingController(text: ligne.description);
    final quantityController =
        TextEditingController(text: ligne.quantity?.toString() ?? '');
    final unitPriceController =
        TextEditingController(text: ligne.unitPrice?.toString() ?? '');
    final salesRateController =
        TextEditingController(text: ligne.salesRate?.toString() ?? '');
    Partner? selectedSupplier;
    List<Partner> suppliers = [];
    bool loadingSuppliers = true;
    String? errorMsg;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            if (loadingSuppliers) {
              PartnerServices().findSuppliers().then((list) {
                setStateModal(() {
                  suppliers = list;
                  if (suppliers.isNotEmpty) {
                    selectedSupplier = suppliers.firstWhere(
                      (s) => s.id == ligne.supplierId,
                      orElse: () => suppliers[0],
                    );
                  } else {
                    selectedSupplier = null;
                  }
                  loadingSuppliers = false;
                });
              }).catchError((e) {
                setStateModal(() {
                  errorMsg = 'Erreur lors du chargement des fournisseurs';
                  loadingSuppliers = false;
                });
              });
            }
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: loadingSuppliers
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()))
                  : errorMsg != null
                      ? Text(errorMsg!)
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Modifier l'article",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 30),
                              buildTextField(
                                controller: descriptionController,
                                label: 'Description',
                                icon: Icons.description,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                spacing: 16,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      controller: quantityController,
                                      label: 'Quantité',
                                      icon: Icons.numbers,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  Expanded(
                                    child: buildTextField(
                                      controller: unitPriceController,
                                      label: 'Prix unitaire',
                                      icon: Icons.attach_money,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              buildTextField(
                                controller: salesRateController,
                                label: 'Taux d\'achat',
                                icon: Icons.percent,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                              ),
                              const SizedBox(height: 12),
                              DropDownCustom<Partner>(
                                items: suppliers,
                                selectedItem: selectedSupplier,
                                onChanged: (val) =>
                                    setStateModal(() => selectedSupplier = val),
                                itemToString: (p) => ((p.firstName +
                                        (p.lastName.isNotEmpty
                                            ? ' ' + p.lastName
                                            : ''))
                                    .trim()),
                                hintText: 'Sélectionner...',
                                prefixIcon: Icons.person,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Annuler'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: confirmationButton(
                                      isLoading: loadingSuppliers,
                                      onPressed: () async {
                                        final user =
                                            await AuthService().getUserInfo();
                                        if (user == null) {
                                          showErrorTopSnackBar(context,
                                              'Utilisateur non connecté');
                                          return;
                                        }
                                        try {
                                          final updatedItem = Items(
                                            id: ligne.id,
                                            description:
                                                descriptionController.text,
                                            quantity: int.tryParse(
                                                quantityController.text),
                                            unitPrice: double.tryParse(
                                                unitPriceController.text),
                                            totalPrice: (int.tryParse(
                                                        quantityController
                                                            .text) ??
                                                    0) *
                                                (double.tryParse(
                                                        unitPriceController
                                                            .text) ??
                                                    0),
                                            supplierId: selectedSupplier?.id,
                                            supplierName: ((selectedSupplier
                                                                ?.firstName ??
                                                            '') +
                                                        ((selectedSupplier
                                                                        ?.lastName ??
                                                                    '')
                                                                .isNotEmpty
                                                            ? ' ' +
                                                                (selectedSupplier
                                                                        ?.lastName ??
                                                                    '')
                                                            : ''))
                                                    .trim()
                                                    .isNotEmpty
                                                ? ((selectedSupplier
                                                            ?.firstName ??
                                                        '') +
                                                    ((selectedSupplier
                                                                    ?.lastName ??
                                                                '')
                                                            .isNotEmpty
                                                        ? ' ' +
                                                            (selectedSupplier
                                                                    ?.lastName ??
                                                                '')
                                                        : ''))
                                                : null,
                                            supplierPhone:
                                                selectedSupplier?.phoneNumber,
                                            packageId: ligne.packageId,
                                            salesRate: double.tryParse(
                                                salesRateController.text),
                                            status: ligne.status,
                                          );
                                          final itemServices = ItemServices();
                                          final result =
                                              await itemServices.updateItem(
                                            itemId: ligne.id!,
                                            userId: user.id,
                                            clientId:
                                                widget.versement.partnerId!,
                                            item: updatedItem,
                                          );
                                          if (result == 'SUCCESS') {
                                            setState(() {
                                              for (var achat in _achats) {
                                                final idx = achat.items
                                                        ?.indexWhere((i) =>
                                                            i.id == ligne.id) ??
                                                    -1;
                                                if (idx != -1) {
                                                  achat.items![idx] =
                                                      updatedItem;
                                                }
                                              }
                                            });
                                            showSuccessTopSnackBar(context,
                                                'Article modifié avec succès');
                                            Navigator.pop(context);
                                          } else if (result ==
                                              'ITEM_NOT_FOUND') {
                                            showErrorTopSnackBar(
                                                context, 'Article non trouvé.');
                                          } else if (result ==
                                              'USER_NOT_FOUND') {
                                            showErrorTopSnackBar(context,
                                                'Utilisateur non trouvé.');
                                          } else if (result ==
                                              'CLIENT_MISMATCH') {
                                            showErrorTopSnackBar(context,
                                                'Client ne correspond pas.');
                                          } else if (result ==
                                              'SUPPLIER_NOT_FOUND') {
                                            showErrorTopSnackBar(context,
                                                'Fournisseur non trouvé.');
                                          } else {
                                            showErrorTopSnackBar(
                                                context, result);
                                          }
                                        } catch (e) {
                                          showErrorTopSnackBar(
                                              context, 'Erreur : $e');
                                        }
                                      },
                                      label: 'Enregistrer',
                                      icon: Icons.save,
                                      subLabel: 'Enregistrement...',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
            );
          },
        );
      },
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

    PurchaseDialog.show(
      context,
      (achat) {
        setState(() {
          _achats = List.from(_achats)..add(achat);
        });
        widget.onVersementUpdated?.call();
      },
      widget.versement.partnerId!,
      widget.versement.id!,
      widget.versement.reference ?? '',
      devise: devise,
      tauxChange: devise?.rate,
    );
    setState(() {
      isLoading = false;
    });
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
                    _buildCollapsibleArticles(),
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
