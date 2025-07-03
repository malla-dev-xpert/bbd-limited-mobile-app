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
  String _searchQuery = '';
  bool isLoading = false;
  bool _isInfoExpanded = true;
  bool _isArticlesExpanded = false;
  late NumberFormat currencyFormat;
  final Set<String> _confirmedArticles = {};
  bool showOperationButtons = false;

  @override
  void initState() {
    super.initState();
    currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: widget.versement.deviseCode ?? 'CNY',
    );
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

  Widget _buildArticleList() {
    final allLignes =
        widget.versement.achats?.expand((a) => a.items ?? []).toList() ?? [];
    final filteredLignes = _searchQuery.isEmpty
        ? allLignes
        : allLignes.where((ligne) {
            final description = (ligne.description ?? '').toLowerCase();
            final itemId = ligne.id?.toString().toLowerCase() ?? '';
            final searchLower = _searchQuery.toLowerCase();
            return description.contains(searchLower) ||
                itemId.contains(searchLower);
          }).toList();

    if (allLignes.isEmpty) {
      return const Center(
        child: Text("Pas d'articles achetés pour ce versement."),
      );
    }

    if (filteredLignes.isEmpty) {
      return const Center(
        child: Text("Aucun article trouvé pour cette recherche."),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: filteredLignes.length,
      itemBuilder: (context, index) {
        final ligne = filteredLignes[index];
        Achat? achat;
        for (var a in widget.versement.achats ?? []) {
          if (a.items?.contains(ligne) ?? false) {
            achat = a;
            break;
          }
        }

        final isConfirmed = _confirmedArticles.contains(ligne.id?.toString());

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
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
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isConfirmed && ligne.status != Status.RECEIVED)
                      ElevatedButton.icon(
                        onPressed: () =>
                            _confirmArticle(ligne.id?.toString() ?? ''),
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
                const SizedBox(height: 4),
                _buildDetailItem('Téléphone', ligne.supplierPhone ?? 'N/A'),
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
          ),
        );
      },
    );
  }

  void _handlePurchase() {
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

    PurchaseDialog.show(
      context,
      (achat) {
        setState(() {
          widget.versement.achats ??= [];
          widget.versement.achats!.add(achat);
        });
        widget.onVersementUpdated?.call();
      },
      widget.versement.partnerId!,
      widget.versement.id!,
      widget.versement.reference ?? '',
    );
    setState(() {
      isLoading = false;
    });
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
                    widget.versement.achats!
                        .expand((a) => a.items ?? [])
                        .length
                        .toString(),
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
            "La liste des articles achetés",
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
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un article...',
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
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: _buildArticleList(),
                  ),
                ],
              ),
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
        for (var achat in widget.versement.achats ?? []) {
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
              widget.onVersementUpdated?.call();
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
