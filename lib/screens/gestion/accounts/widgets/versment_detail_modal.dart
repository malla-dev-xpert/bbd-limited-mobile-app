import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/purchase_dialog.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:intl/intl.dart';
import 'package:iconify_flutter/icons/majesticons.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:bbd_limited/models/achats/achat.dart';

Widget _detailRow(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$label :", style: TextStyle(fontWeight: FontWeight.w500)),
        Flexible(
          child: Text(
            value ?? '',
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _detailItem(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    spacing: 10,
    children: [
      Expanded(
        flex: 2,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ),
      Expanded(
        flex: 3,
        child: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

void showVersementDetailsBottomSheet(
  BuildContext context,
  Versement versement,
  VoidCallback? onVersementUpdated,
) async {
  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    transitionAnimationController: AnimationController(
      vsync: Scaffold.of(context),
      duration: const Duration(milliseconds: 300),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (context) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        final allLignes =
            versement.achats?.expand((a) => a.lignes ?? []).toList() ?? [];
        final filteredLignes = searchQuery.isEmpty
            ? allLignes
            : allLignes.where((ligne) {
                final description = (ligne.descriptionItem ?? '').toLowerCase();
                final itemId = ligne.itemId?.toString().toLowerCase() ?? '';
                final searchLower = searchQuery.toLowerCase();
                return description.contains(searchLower) ||
                    itemId.contains(searchLower);
              }).toList();

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Détails du versement",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.grey[800],
                        ),
                        child: IconButton(
                          onPressed: () => {Navigator.of(context).pop()},
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _detailRow("Référence", versement.reference),
                  _detailRow("Client", versement.partnerName),
                  _detailRow("Téléphone", "${versement.partnerPhone}"),
                  _detailRow("Commissionnaire",
                      versement.commissionnaireName ?? 'N/V'),
                  _detailRow("Téléphone", "${versement.commissionnairePhone}"),
                  _detailRow(
                    "Montant versé",
                    currencyFormat.format(versement.montantVerser),
                  ),
                  _detailRow(
                    "Montant restante",
                    currencyFormat.format(versement.montantRestant),
                  ),
                  _detailRow(
                    "Date de versement",
                    DateFormat('dd/MM/yyyy HH:mm').format(versement.createdAt!),
                  ),
                  _detailRow(
                    "Total des achats",
                    versement.achats!
                        .expand((a) => a.lignes ?? [])
                        .length
                        .toString(),
                  ),
                  const Divider(),
                  const Text(
                    "La liste des articles achetés",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un article...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: versement.achats == null ||
                            versement.achats!.isEmpty ||
                            versement.achats!.every(
                              (a) => a.lignes == null || a.lignes!.isEmpty,
                            )
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Pas d'articles achetés pour ce versement.",
                                ),
                              ],
                            ),
                          )
                        : filteredLignes.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Aucun article trouvé pour cette recherche.",
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: filteredLignes.length,
                                itemBuilder: (context, index) {
                                  final ligne = filteredLignes[index];
                                  Achat? achat;
                                  for (var a in versement.achats ?? []) {
                                    if (a.lignes?.contains(ligne) ?? false) {
                                      achat = a;
                                      break;
                                    }
                                  }

                                  return Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[50],
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ligne.descriptionItem ??
                                                'Article sans nom',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          if (achat?.fournisseur != null) ...[
                                            const SizedBox(height: 4),
                                            _detailItem(
                                              'Fournisseur',
                                              '${achat!.fournisseur} | ${achat.fournisseurPhone}',
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          _detailItem(
                                            'Quantité',
                                            '${ligne.quantity}',
                                          ),
                                          const SizedBox(height: 4),
                                          _detailItem(
                                            'Prix Unitaire',
                                            currencyFormat
                                                .format(ligne.unitPriceItem),
                                          ),
                                          const SizedBox(height: 4),
                                          _detailItem(
                                            'Total',
                                            currencyFormat
                                                .format(ligne.prixTotal),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (versement.partnerId == null ||
                            versement.id == null) {
                          showErrorTopSnackBar(
                            context,
                            "Informations du versement incomplètes",
                          );
                          return;
                        }

                        // Fermer d'abord le bottom sheet
                        Navigator.of(context).pop();

                        // Attendre un court instant avant d'ouvrir le dialogue
                        Future.delayed(const Duration(milliseconds: 100), () {
                          PurchaseDialog.show(
                            context,
                            (achat) {
                              onVersementUpdated?.call();
                            },
                            versement.partnerId!,
                            versement.id!,
                          );
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1E49),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      label: const Text(
                        'Effectuer un achat',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      icon: const Iconify(
                        Majesticons.money_hand_line,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
