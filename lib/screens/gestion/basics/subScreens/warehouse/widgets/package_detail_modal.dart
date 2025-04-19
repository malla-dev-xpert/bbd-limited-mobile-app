import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
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
        Expanded(
          child: Text(
            value ?? '',
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
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

void showPackageDetailsBottomSheet(BuildContext context, Packages pkg) {
  final PackageServices packageServices = PackageServices();
  final AuthService authService = AuthService();
  bool isLoading = false;

  showModalBottomSheet(
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
                      Text(
                        "La liste des articles",
                        style: TextStyle(fontWeight: FontWeight.w700),
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
                                        onPressed:
                                            () => showAddItemsModal(
                                              context,
                                              pkg.id,
                                            ),
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
                      ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon:
                            isLoading
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Icon(Icons.check, color: Colors.white),
                        label: Text(
                          isLoading
                              ? "Confirmation..."
                              : "Confirmer la réception",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed:
                            isLoading
                                ? null
                                : () async {
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
