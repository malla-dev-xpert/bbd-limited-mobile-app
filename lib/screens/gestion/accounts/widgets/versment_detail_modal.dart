import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/purchase_dialog.dart';
import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:intl/intl.dart';
import 'package:iconify_flutter/icons/majesticons.dart';

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

void showVersementDetailsBottomSheet(
  BuildContext context,
  Versement versement,
  final bool isVersementScreen,
) async {
  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');

  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    transitionAnimationController: AnimationController(
      vsync: Scaffold.of(context),
      duration: Duration(milliseconds: 300),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder:
        (context) => StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Wrap(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
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
                          icon: Icon(
                            Icons.clear,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  _detailRow("Référence", versement.reference),
                  _detailRow("Client", versement.partnerName),
                  _detailRow("Téléphone", "${versement.partnerPhone}"),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "La liste des articles achetés",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child:
                            versement.achats == null ||
                                    versement.achats!.isEmpty ||
                                    versement.achats!.every(
                                      (a) =>
                                          a.lignes == null || a.lignes!.isEmpty,
                                    )
                                ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Pas d'articles achetés pour ce versement.",
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount:
                                      versement.achats!
                                          .expand((a) => a.lignes ?? [])
                                          .length,
                                  itemBuilder: (context, index) {
                                    final allLignes =
                                        versement.achats!
                                            .expand((a) => a.lignes ?? [])
                                            .toList();
                                    final ligne = allLignes[index];

                                    return Container(
                                      margin: EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[50],
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ligne.descriptionItem ??
                                                  'Article sans nom',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Quantité: ${ligne.quantity}',
                                                ),
                                                Text(
                                                  'P.U: ${currencyFormat.format(ligne.unitPriceItem)}',
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Total: ${currencyFormat.format(ligne.prixTotal)}',
                                                ),
                                                if (ligne.itemId != null)
                                                  Text('Ref: ${ligne.itemId}'),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                      if (isVersementScreen == false)
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.bottom,
                          ),
                          child: ElevatedButton.icon(
                            onPressed:
                                () => PurchaseDialog.show(context, (achat) {
                                  // TODO: Handle the purchase completion
                                  Navigator.pop(context);
                                }),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1E49),
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            label: Text(
                              'Effectuer un achat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            icon: Iconify(
                              Majesticons.money_hand_line,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
  );
}
