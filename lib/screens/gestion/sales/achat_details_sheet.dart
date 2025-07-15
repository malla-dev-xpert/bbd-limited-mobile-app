import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class AchatDetailsSheet extends StatefulWidget {
  final Achat achat;

  const AchatDetailsSheet({super.key, required this.achat});

  @override
  State<AchatDetailsSheet> createState() => _AchatDetailsSheetState();
}

class _AchatDetailsSheetState extends State<AchatDetailsSheet> {
  bool isLoading = false;
  final Set<String> confirmedArticles = {};
  final AchatServices achatServices = AchatServices();

  // Ajout pour la recherche
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  Future<void> confirmArticle(String itemId) async {
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
      final result = await achatServices.confirmDelivery(
        itemIds: [int.parse(itemId)],
        userId: user.id,
      );

      if (result.isSuccess) {
        setState(() {
          confirmedArticles.add(itemId);
          // Met à jour le statut de l'article dans la liste locale
          final idx = widget.achat.items
                  ?.indexWhere((i) => i.id?.toString() == itemId) ??
              -1;
          if (idx != -1) {
            widget.achat.items![idx].status = Status.RECEIVED;
          }
        });
        showSuccessTopSnackBar(context, "Article reçu avec succès");
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

  void _showEditArticleDialog(Items item) async {
    final descriptionController = TextEditingController(text: item.description);
    final quantityController =
        TextEditingController(text: item.quantity?.toString() ?? '');
    final unitPriceController =
        TextEditingController(text: item.unitPrice?.toString() ?? '');
    final salesRateController =
        TextEditingController(text: item.salesRate?.toString() ?? '');
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
                      (s) => s.id == item.supplierId,
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
                                      icon: Icons.save,
                                      label: 'Enregistrer',
                                      isLoading: isLoading,
                                      subLabel: '',
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
                                            id: item.id,
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
                                            packageId: item.packageId,
                                            salesRate: double.tryParse(
                                                salesRateController.text),
                                            status: item.status,
                                          );
                                          final itemServices = ItemServices();
                                          final result =
                                              await itemServices.updateItem(
                                            itemId: item.id!,
                                            userId: user.id,
                                            clientId:
                                                widget.achat.clientId ?? 0,
                                            item: updatedItem,
                                          );
                                          if (result == 'SUCCESS') {
                                            setState(() {
                                              final idx = widget.achat.items
                                                      ?.indexWhere((i) =>
                                                          i.id == item.id) ??
                                                  -1;
                                              if (idx != -1) {
                                                widget.achat.items![idx] =
                                                    updatedItem;
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

  void _confirmDeleteArticle(Items item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange)),
            const SizedBox(width: 12),
            const Text('Attention',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
            'Vous allez supprimer  l\'article "${item.description}" de votre liste d\'achats.\nCette action est irréversible.'),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _deleteArticle(item);
              Navigator.pop(context);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteArticle(Items item) async {
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
        item.id!,
        user.id,
        widget.achat.clientId ?? 0,
      );
      if (result == "DELETED") {
        setState(() {
          widget.achat.items?.remove(item);
        });
        showSuccessTopSnackBar(context, "Article supprimé avec succès");
        Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    final achat = widget.achat;
    // Filtrage des articles selon la recherche
    final List<Items> filteredItems = (achat.items ?? []).where((item) {
      final query = _searchQuery.toLowerCase();
      final description = (item.description ?? '').toLowerCase();
      final invoice = (item.invoiceNumber ?? '').toLowerCase();
      return query.isEmpty ||
          description.contains(query) ||
          invoice.contains(query);
    }).toList();
    return Container(
      // MODIFIE : largeur max
      width: MediaQuery.of(context).size.width,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Détails de l\'achat',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  if (achat.isDebt == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7F78AF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF7F78AF)),
                      ),
                      child: const Text(
                        'Dette',
                        style: TextStyle(
                          color: Color(0xFF7F78AF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Champ de recherche ajouté ici
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou facture...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: BorderSide(color: Colors.grey),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
              achat.isDebt == true ? 'Identifiant' : 'Référence',
              achat.isDebt == true
                  ? achat.id.toString()
                  : (achat.referenceVersement ?? "N/A")),
          _buildInfoRow('Client', achat.client ?? "N/A"),
          if (achat.clientPhone != null)
            _buildInfoRow('Téléphone', achat.clientPhone!),
          _buildInfoRow('Montant de l\'achat',
              '${_formatAmount(achat.montantTotal ?? 0)} ¥'),
          const SizedBox(height: 20),
          const Text(
            'Articles achetés',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (filteredItems.isNotEmpty)
            ...filteredItems.map((item) => _buildItemCard(item, achat))
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Aucun article trouvé'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isAmount ? 18 : 16,
              fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
              color: isAmount ? const Color(0xFF1A1E49) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Items item, Achat achat) {
    final isConfirmed = confirmedArticles.contains(item.id?.toString());
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne titre + actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Titre
              Expanded(
                child: Text(
                  item.description ?? 'Article sans nom',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF1A1E49),
                  ),
                ),
              ),
              // Actions éditer/supprimer
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF1976D2)),
                    tooltip: 'Modifier',
                    onPressed: () => _showEditArticleDialog(item),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFD32F2F)),
                    tooltip: 'Supprimer',
                    onPressed: () => _confirmDeleteArticle(item),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoIconText(
                icon: Icons.numbers,
                label: 'Quantité',
                value: '${item.quantity ?? 0}',
              ),
              const SizedBox(width: 16),
              _InfoIconText(
                icon: Icons.attach_money,
                label: 'Prix unitaire',
                value: _formatAmount(item.unitPrice ?? 0) + ' ¥',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoIconText(
                icon: Icons.business_outlined,
                label: 'Fournisseur',
                value: item.supplierName ?? 'N/A',
              ),
              if (item.supplierPhone != null &&
                  (item.supplierPhone as String).isNotEmpty) ...[
                const SizedBox(width: 16),
                _InfoIconText(
                  icon: Icons.phone,
                  label: 'Téléphone',
                  value: item.supplierPhone ?? '',
                ),
              ],
              const SizedBox(width: 16),
              _InfoIconText(
                icon: Icons.percent,
                label: 'Taux achat',
                value: (item.salesRate?.toString() ?? ''),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoIconText(
            icon: Icons.calculate,
            label: 'Total',
            value: _formatAmount(item.totalPrice ??
                    (item.quantity ?? 0) * (item.unitPrice ?? 0)) +
                ' ¥',
          ),
          // Statut et actions de confirmation
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isConfirmed && item.status != Status.RECEIVED)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_long,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            item.invoiceNumber ?? '',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () =>
                          confirmArticle(item.id?.toString() ?? ''),
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.white),
                      label: Text(isLoading ? "Chargement..." : "Confirmer"),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1E49),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              if (item.status == Status.RECEIVED)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        item.invoiceNumber ?? '',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget utilitaire pour afficher une info avec icône
class _InfoIconText extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoIconText(
      {required this.icon, required this.label, required this.value, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text('$label: ',
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1A1E49))),
      ],
    );
  }
}
