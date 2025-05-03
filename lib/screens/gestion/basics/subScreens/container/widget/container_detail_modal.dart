import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/models/container.dart';
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

void showContainerDetailsBottomSheet(
  BuildContext context,
  Containers container,
) async {
  final PackageServices packageServices = PackageServices();
  final AuthService authService = AuthService();
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
                        "Détails du conteneur",
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
                  _detailRow("Référence", container.reference),
                  _detailRow(
                    "Disponibilité",
                    container.isAvailable == true
                        ? 'Disponible'
                        : 'Indisponible',
                  ),
                  _detailRow(
                    "Date de reception",
                    DateFormat.yMMMMEEEEd().format(container.createdAt!),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "La liste des colis",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          container.status == Status.PENDING
                              ? TextButton.icon(
                                onPressed: () async {
                                  final result = await showAddItemsModal(
                                    context,
                                    container.id!,
                                  );
                                  // if (result == true) {
                                  //   final updatedItems = await itemServices
                                  //       .findByPackageId(container.id);
                                  //   setState(() {
                                  //     container.items = updatedItems;
                                  //   });
                                  // }
                                },
                                label: Text("Ajouter des colis"),
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
                            container.packages == null ||
                                    container.packages!.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("Pas de colis pour ce conteneur."),
                                      const SizedBox(height: 10),
                                      if (container.status != Status.RECEIVED)
                                        ElevatedButton.icon(
                                          onPressed: () async {},
                                          icon: Icon(
                                            Icons.add,
                                            color: Colors.white,
                                          ),
                                          label: Text(
                                            "Ajouter un colis",
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
                                      container.packages!
                                          .where(
                                            (ctn) =>
                                                ctn.status != Status.DELETE,
                                          )
                                          .length,
                                  itemBuilder: (context, index) {
                                    final ctn = container.packages![index];

                                    return Dismissible(
                                      key: Key('${ctn.id}'),
                                      direction:
                                          container.status != Status.INPROGRESS
                                              ? DismissDirection.endToStart
                                              : DismissDirection.none,
                                      background: Container(
                                        padding: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        color:
                                            container.status != Status.RECEIVED
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
                                          container.status != Status.INPROGRESS
                                              ? (direction) async {}
                                              : null,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color: Colors.grey[50],
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _detailRow(
                                              "Référence",
                                              ctn.reference,
                                            ),
                                            _detailRow(
                                              "Client",
                                              ctn.partnerName,
                                            ),
                                            _detailRow(
                                              "Téléphone",
                                              ctn.partnerPhoneNumber,
                                            ),
                                            _detailRow(
                                              "Nombre  d'articles",
                                              ctn.items!.length.toString(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),
                  container.packages != null &&
                          container.packages!.isNotEmpty &&
                          container.status != Status.RECEIVED
                      ? confirmationButton(
                        subLabel: "Démarrage...",
                        icon: Icons.check,
                        label: "Démarrer la livraison",
                        isLoading: isLoading,
                        onPressed: () async {
                          setState(() {
                            isLoading = true;
                          });

                          final user = await authService.getUserInfo();

                          try {
                            await packageServices.receivePackage(
                              container.id!,
                              user?.id.toInt(),
                              container.userId,
                            );

                            Navigator.of(context).pop(true);

                            showSuccessTopSnackBar(
                              context,
                              "Livraison démarrée avec succès !",
                            );
                          } catch (e) {
                            print(e);
                            showErrorTopSnackBar(
                              context,
                              "Erreur lors du démarrage de la livraison",
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
