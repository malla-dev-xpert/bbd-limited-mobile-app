import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/container/widget/add_package_to_container_modal.dart';
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
  final ContainerServices containerServices = ContainerServices();
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
                          container.status == Status.PENDING &&
                                  container.isAvailable == true
                              ? TextButton.icon(
                                onPressed: () async {
                                  final selectedPackages =
                                      await showAddPackagesToContainerDialog(
                                        context,
                                        container.id!,
                                        packageServices,
                                      );

                                  if (selectedPackages != null &&
                                      selectedPackages.isNotEmpty) {
                                    // Rafraîchir les données du conteneur
                                    final updatedContainer =
                                        await containerServices
                                            .getContainerDetails(container.id!);

                                    setState(() {
                                      container = updatedContainer;
                                    });
                                  }
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
                                    ],
                                  ),
                                )
                                : RefreshIndicator(
                                  onRefresh: () async {
                                    await container.packages!;
                                  },
                                  displacement: 40,
                                  color: Theme.of(context).primaryColor,
                                  backgroundColor: Colors.white,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount:
                                        container.packages!
                                            .where(
                                              (ctn) =>
                                                  ctn.status != Status.DELETE ||
                                                  ctn.status !=
                                                      Status
                                                          .DELETE_ON_CONTAINER,
                                            )
                                            .length,
                                    itemBuilder: (context, index) {
                                      final pkg = container.packages![index];

                                      return Dismissible(
                                        key: Key('${pkg.id}'),
                                        direction:
                                            container.status !=
                                                    Status.INPROGRESS
                                                ? DismissDirection.endToStart
                                                : DismissDirection.none,
                                        background: Container(
                                          padding: const EdgeInsets.only(
                                            right: 16,
                                          ),
                                          color:
                                              container.status !=
                                                      Status.RECEIVED
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
                                            container.status !=
                                                    Status.INPROGRESS
                                                ? (direction) async {
                                                  final bool
                                                  confirm = await showDialog(
                                                    context: context,
                                                    builder: (
                                                      BuildContext context,
                                                    ) {
                                                      return AlertDialog(
                                                        backgroundColor:
                                                            Colors.white,
                                                        title: Text(
                                                          "Confirmation",
                                                        ),
                                                        content: Text(
                                                          "Voulez-vous vraiment retirer ce colis du conteneur ?",
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.of(
                                                                      context,
                                                                    ).pop(
                                                                      false,
                                                                    ),
                                                            child: Text(
                                                              "Annuler",
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.of(
                                                                      context,
                                                                    ).pop(true),
                                                            child: Text(
                                                              isLoading
                                                                  ? "Suppression..."
                                                                  : "Confirmer",
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );

                                                  if (confirm != true)
                                                    return false;

                                                  try {
                                                    final user =
                                                        await authService
                                                            .getUserInfo();
                                                    setState(() {
                                                      isLoading = true;
                                                    });
                                                    final result =
                                                        await packageServices
                                                            .deletePackageOnContainer(
                                                              pkg.id,
                                                              user!.id.toInt(),
                                                              container.id,
                                                            );

                                                    if (result == "DELETED") {
                                                      setState(() {
                                                        container.packages!
                                                            .removeWhere(
                                                              (p) =>
                                                                  p.id ==
                                                                  pkg.id,
                                                            );
                                                      });
                                                      showSuccessTopSnackBar(
                                                        context,
                                                        "Colis retiré du conteneur",
                                                      );
                                                      return true;
                                                    } else if (result ==
                                                        "PACKAGES_NOT_FOR_CONTAINER") {
                                                      showErrorTopSnackBar(
                                                        context,
                                                        "Le colis n'appartient pas à ce conteneur",
                                                      );
                                                    } else if (result ==
                                                        "CONTAINER_IN_PROGRESS") {
                                                      showErrorTopSnackBar(
                                                        context,
                                                        "Impossible de retirer un colis d'un conteneur en cours de livraison",
                                                      );
                                                    }
                                                  } catch (e) {
                                                    showErrorTopSnackBar(
                                                      context,
                                                      "Erreur lors de la suppression",
                                                    );
                                                  } finally {
                                                    setState(() {
                                                      isLoading = false;
                                                    });
                                                  }
                                                  return false;
                                                }
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
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 5,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _detailRow(
                                                "Référence",
                                                pkg.reference,
                                              ),
                                              _detailRow(
                                                "Client",
                                                pkg.partnerName,
                                              ),
                                              _detailRow(
                                                "Téléphone",
                                                pkg.partnerPhoneNumber,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),
                  container.packages != null &&
                          container.packages!.isNotEmpty &&
                          container.status == Status.PENDING
                      ? confirmationButton(
                        subLabel: "Démarrage...",
                        icon: Icons.check,
                        label: "Démarrer la livraison",
                        isLoading: isLoading,
                        onPressed: () async {
                          final bool confirm = await showDialog(
                            context: context,

                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Confirmer le démarrage"),
                                backgroundColor: Colors.white,
                                content: Text(
                                  "Voulez-vous vraiment démarrer la livraison de ce conteneur ?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: Text("Annuler"),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    child: Text(
                                      isLoading ? "Démarrage..." : "Confirmer",
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          // Si l'utilisateur annule, on ne fait rien
                          if (confirm != true) return;

                          setState(() {
                            isLoading = true;
                          });

                          final user = await authService.getUserInfo();

                          if (user == null) {
                            showErrorTopSnackBar(
                              context,
                              "Erreur: Utilisateur non connecté",
                            );
                            setState(() => isLoading = false);
                            return;
                          }

                          try {
                            final result = await containerServices
                                .startDelivery(container.id!, user.id.toInt());

                            if (result == "SUCCESS") {
                              Navigator.of(context).pop(true);
                              showSuccessTopSnackBar(
                                context,
                                "Livraison démarrée avec succès !",
                              );
                            } else if (result == "NO_PACKAGE_FOR_DELIVERY") {
                              showErrorTopSnackBar(
                                context,
                                "Impossible de démarrer la livraison, pas de colis dans le conteneur.",
                              );
                            }
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
