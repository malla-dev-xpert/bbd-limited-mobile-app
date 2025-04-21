import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
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

void showPackageDetailsBottomSheet(
  BuildContext context,
  Packages pkg,
  int warehouseId,
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
                                    pkg.id,
                                  );
                                  if (result == true) {
                                    final updatedItems = await itemServices
                                        .findByPackageId(pkg.id);
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
                                      Text("Pas d’articles pour ce colis."),
                                      const SizedBox(height: 10),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final result = showAddItemsModal(
                                            context,
                                            pkg.id,
                                          );
                                          if (result == true) {
                                            final updatedPackage =
                                                await itemServices
                                                    .findByPackageId(pkg.id);

                                            setState(() {
                                              pkg.items = updatedPackage;
                                            });
                                          }
                                        },
                                        icon: Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          "Ajouter un article",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF7F78AF,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: pkg.items!.length,
                                  itemBuilder: (context, index) {
                                    final item = pkg.items![index];
                                    return ListTile(
                                      leading: Icon(Icons.label),
                                      title: Text(item.description),
                                      trailing: Text("x${item.quantity}"),
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
                              pkg.id,
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
