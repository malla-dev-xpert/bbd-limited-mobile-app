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
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.save),
                                      label: const Text('Enregistrer'),
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
                                                0, // Remplacer par l'ID réel du client si disponible
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
        title: const Text('Supprimer cet article ?'),
        content: const Text('Cette action est irréversible.'),
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
    return Container(
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
          if (achat.items != null && achat.items!.isNotEmpty)
            ...achat.items!.map((item) => _buildItemCard(item, achat))
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.description ?? "N/A",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Modifier',
                onPressed: () => _showEditArticleDialog(item),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Supprimer',
                onPressed: () => _confirmDeleteArticle(item),
              ),
              if (!isConfirmed && item.status != Status.RECEIVED)
                ElevatedButton.icon(
                  onPressed: () => confirmArticle(item.id?.toString() ?? ''),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(isLoading ? "Chargement..." : "Confirmer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1E49),
                    foregroundColor: Colors.white,
                  ),
                )
              else if (isConfirmed || item.status == Status.RECEIVED)
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantité: ${item.quantity ?? 0}',
                style: TextStyle(color: Colors.grey[700]!, fontSize: 15),
              ),
              Text(
                'Prix unitaire: ${_formatAmount(item.unitPrice ?? 0)} ¥',
                style: TextStyle(color: Colors.grey[700]!, fontSize: 15),
              ),
            ],
          ),
          if (item.totalPrice != null) ...[
            const SizedBox(height: 8),
            Text(
              'Total: ${_formatAmount(item.totalPrice ?? 0)} ¥',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1E49),
              ),
            ),
          ],
          if (item.supplierName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.business_outlined,
                  size: 16,
                  color: Colors.grey[700]!,
                ),
                const SizedBox(width: 8),
                Text(
                  item.supplierName!,
                  style: TextStyle(color: Colors.grey[700]!, fontSize: 15),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
