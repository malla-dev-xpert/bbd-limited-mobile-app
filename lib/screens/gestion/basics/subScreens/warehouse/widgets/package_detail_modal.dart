import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/models/items.dart';
import 'package:bbd_limited/models/packages.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/warehouse/widgets/add_items_modal.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

Future<bool?> _showEditItemModal(
  BuildContext context,
  Item item,
  Packages pkg,
) async {
  final TextEditingController descriptionController = TextEditingController(
    text: item.description,
  );
  final TextEditingController quantityController = TextEditingController(
    text: item.quantity.toString(),
  );
  final AuthService authService = AuthService();
  bool _isLoading = false;
  final ItemServices itemServices = ItemServices();

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 50,
              children: [
                const Text(
                  'Modifier l\'article',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildTextField(
                    controller: descriptionController,
                    label: "Description",
                    icon: Icons.description,
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    label: "Quantité",
                    icon: Icons.numbers,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton.icon(
                onPressed: () async {
                  try {
                    final user = await authService.getUserInfo();
                    if (user == null) return;

                    setState(() => _isLoading = true);

                    final itemDto = item.copyWith(
                      description: descriptionController.text,
                      quantity: double.parse(quantityController.text),
                    );

                    final updatedItem = await itemServices.updateItem(
                      item.id,
                      pkg.id,
                      itemDto,
                    );

                    // if (updatedItem != null) {
                    //   final updatedItems =
                    //       pkg.items
                    //           ?.map((i) => i.id == item.id ? updatedItem : i)
                    //           .toList();

                    //   setState(() {
                    //     _isLoading = false;
                    //   });

                    //   Navigator.pop(context, true);

                    //   showSuccessTopSnackBar(
                    //     context,
                    //     "Article modifié avec succès",
                    //   );
                    // }
                  } catch (e) {
                    setState(() => _isLoading = false);
                    showErrorTopSnackBar(context, "Erreur: ${e.toString()}");
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
                icon: const Icon(
                  Icons.check_circle_outline_outlined,
                  color: Colors.green,
                ),
                label:
                    _isLoading
                        ? const Text('Modification...')
                        : Text(
                          'Modifier',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
              ),
            ],
          );
        },
      );
    },
  );
}

void showPackageDetailsBottomSheet(
  BuildContext context,
  Packages pkg,
  int warehouseId,
  bool? isPackageScreen,
) async {
  final PackageServices packageServices = PackageServices();
  final AuthService authService = AuthService();
  final ItemServices itemServices = ItemServices();
  bool isLoading = false;

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
                        "Détails du colis",
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
                  _detailRow("Référence", pkg.ref),
                  _detailRow(
                    "Dimensions",
                    pkg.expeditionType == "Avion"
                        ? pkg.weight.toString()
                        : pkg.cbn.toString(),
                  ),
                  _detailRow("Poids", "${pkg.weight} kg"),
                  isPackageScreen == true
                      ? _detailRow(
                        "Entrepot",
                        pkg.warehouseName ?? "Non trouver",
                      )
                      : Text(""),
                  _detailRow(
                    "Date de reception",
                    DateFormat.yMMMMEEEEd().format(pkg.startDate!),
                  ),
                  _detailRow("Client", pkg.clientName ?? "Non trouver"),
                  _detailRow("Téléphone", pkg.clientPhone ?? "Non trouver"),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "La liste des articles",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          pkg.status == Status.PENDING
                              ? TextButton.icon(
                                onPressed: () async {
                                  final result = await showAddItemsModal(
                                    context,
                                    pkg.id!,
                                  );
                                  // if (result == true) {
                                  //   final updatedItems = await itemServices
                                  //       .findByPackageId(pkg.id!);
                                  //   setState(() {
                                  //     pkg.items = updatedItems;
                                  //   });
                                  // }
                                },
                                label: Text("Ajouter des articles"),
                                icon: Icon(Icons.add),
                              )
                              : Text(""),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
  );
}
