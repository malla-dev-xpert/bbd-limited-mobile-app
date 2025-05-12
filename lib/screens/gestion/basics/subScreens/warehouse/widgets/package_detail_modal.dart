import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/models/items.dart';
import 'package:bbd_limited/models/package.dart';
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

                    if (updatedItem != null) {
                      final updatedItems =
                          pkg.items
                              ?.map((i) => i.id == item.id ? updatedItem : i)
                              .toList();

                      setState(() {
                        _isLoading = false;
                      });

                      Navigator.pop(context, true);

                      showSuccessTopSnackBar(
                        context,
                        "Article modifié avec succès",
                      );
                    }
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
                  _detailRow("Référence", pkg.reference),
                  _detailRow("Dimensions", pkg.dimensions),
                  _detailRow("Poids", "${pkg.weight} kg"),
                  isPackageScreen == true
                      ? _detailRow(
                        "Entrepot",
                        pkg.warehouseName ?? "Non trouver",
                      )
                      : Text(""),
                  _detailRow(
                    "Date de reception",
                    DateFormat.yMMMMEEEEd().format(pkg.createdAt!),
                  ),
                  _detailRow("Client", pkg.partnerName ?? "Non trouver"),
                  _detailRow(
                    "Téléphone",
                    pkg.partnerPhoneNumber ?? "Non trouver",
                  ),
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
                                  if (result == true) {
                                    final updatedItems = await itemServices
                                        .findByPackageId(pkg.id!);
                                    setState(() {
                                      pkg.items = updatedItems;
                                    });
                                  }
                                },
                                label: Text("Ajouter des articles"),
                                icon: Icon(Icons.add),
                              )
                              : Text(""),
                        ],
                      ),
                      const SizedBox(height: 10),

                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child:
                            pkg.items == null || pkg.items!.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("Pas d'articles pour ce colis."),
                                      const SizedBox(height: 10),
                                      if (pkg.status != Status.RECEIVED)
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            final result =
                                                await showAddItemsModal(
                                                  context,
                                                  pkg.id!,
                                                );
                                            if (result == true) {
                                              final updatedItems =
                                                  await itemServices
                                                      .findByPackageId(pkg.id!);
                                              setState(() {
                                                pkg.items = updatedItems;
                                              });
                                            }
                                          },
                                          icon: Icon(
                                            Icons.add,
                                            color: Colors.white,
                                          ),
                                          label: Text(
                                            "Ajouter un article",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF7F78AF,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount:
                                      pkg.items!
                                          .where(
                                            (item) =>
                                                item.status != Status.DELETE,
                                          )
                                          .length,
                                  itemBuilder: (context, index) {
                                    final item = pkg.items![index];

                                    return Dismissible(
                                      key: Key('${item.id}'),
                                      direction:
                                          pkg.status != Status.RECEIVED
                                              ? DismissDirection.endToStart
                                              : DismissDirection.none,
                                      background: Container(
                                        padding: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        color:
                                            pkg.status != Status.RECEIVED
                                                ? Colors.red
                                                : Colors.grey,
                                        alignment: Alignment.centerRight,
                                        child: Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                      confirmDismiss:
                                          pkg.status != Status.RECEIVED
                                              ? (direction) async {
                                                try {
                                                  final user =
                                                      await authService
                                                          .getUserInfo();
                                                  if (user == null) {
                                                    showErrorTopSnackBar(
                                                      context,
                                                      "Erreur: Utilisateur non connecté",
                                                    );
                                                    return false;
                                                  }

                                                  final response =
                                                      await itemServices
                                                          .deleteItem(
                                                            item.id,
                                                            user.id.toInt(),
                                                            pkg.id!,
                                                          );

                                                  if (response ==
                                                      "ITEM_NOT_FOUND") {
                                                    showErrorTopSnackBar(
                                                      context,
                                                      "Article non trouvé.",
                                                    );
                                                    return false;
                                                  } else if (response ==
                                                      "PACKAGE_NOT_FOUND") {
                                                    showErrorTopSnackBar(
                                                      context,
                                                      "Colis non trouvé.",
                                                    );
                                                    return false;
                                                  } else if (response ==
                                                      "DELETED") {
                                                    final updatedItems =
                                                        await itemServices
                                                            .findByPackageId(
                                                              pkg.id!,
                                                            );
                                                    setState(() {
                                                      pkg.items = updatedItems;
                                                    });
                                                    showSuccessTopSnackBar(
                                                      context,
                                                      "Article supprimé avec succès",
                                                    );
                                                    return true;
                                                  }
                                                  return false;
                                                } catch (e) {
                                                  showErrorTopSnackBar(
                                                    context,
                                                    "Erreur lors de la suppression: ${e.toString()}",
                                                  );
                                                  return false;
                                                }
                                              }
                                              : null,
                                      child: ListTile(
                                        onTap:
                                            pkg.status == Status.RECEIVED
                                                ? null
                                                : () async {
                                                  final result =
                                                      await _showEditItemModal(
                                                        context,
                                                        item,
                                                        pkg,
                                                      );
                                                  if (result == true) {
                                                    final updatedItems =
                                                        await itemServices
                                                            .findByPackageId(
                                                              pkg.id!,
                                                            );
                                                    setState(() {
                                                      pkg.items = updatedItems;
                                                    });
                                                  }
                                                },

                                        leading: Icon(Icons.label),
                                        title: Text(item.description),
                                        trailing: Text("x${item.quantity}"),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),
                  pkg.items != null &&
                          pkg.items!.isNotEmpty &&
                          pkg.status != Status.RECEIVED
                      ? confirmationButton(
                        subLabel: "Confirmation...",
                        icon: Icons.check,
                        label: "Confirmer la réception",
                        isLoading: isLoading,
                        onPressed: () async {
                          setState(() {
                            isLoading = true;
                          });

                          final user = await authService.getUserInfo();

                          try {
                            await packageServices.receivePackage(
                              pkg.id!,
                              user?.id.toInt(),
                              pkg.warehouseId,
                            );

                            setState(() {
                              pkg.status = Status.RECEIVED;
                            });

                            Navigator.of(context).pop(true);

                            showSuccessTopSnackBar(
                              context,
                              "Réception confirmée !",
                            );
                          } catch (e) {
                            print(e);
                            showErrorTopSnackBar(
                              context,
                              "Erreur lors de la réception",
                            );
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        },
                      )
                      : Text(""),
                  const SizedBox(height: 70),
                ],
              ),
            );
          },
        ),
  );
}
