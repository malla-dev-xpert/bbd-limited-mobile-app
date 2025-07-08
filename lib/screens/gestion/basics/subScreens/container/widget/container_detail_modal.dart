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
        Text("$label :", style: const TextStyle(fontWeight: FontWeight.w500)),
        Flexible(
          child: Text(
            value ?? '',
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

void showContainerDetailsBottomSheet(BuildContext context, Containers container,
    {Function(Containers)? onContainerUpdated}) async {
  final PackageServices packageServices = PackageServices();
  final ContainerServices containerServices = ContainerServices();
  final AuthService authService = AuthService();
  bool isLoading = false;
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
        // Filtrer les colis en fonction de la recherche
        final filteredPackages = container.packages?.where((pkg) {
          if (searchQuery.isEmpty) return true;
          final query = searchQuery.toLowerCase();
          return pkg.ref?.toLowerCase().contains(query) == true ||
              pkg.clientName?.toLowerCase().contains(query) == true ||
              pkg.clientPhone?.toLowerCase().contains(query) == true;
        }).toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
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
              _detailRow("Référence", container.reference),
              _detailRow("Taille", "${container.size} pieds"),
              _detailRow(
                "Disponibilité",
                container.isAvailable == true ? 'Disponible' : 'Indisponible',
              ),
              _detailRow(
                  "Fournisseur",
                  container.supplier_id != null
                      ? '${container.supplierName ?? ""} ${container.supplierPhone?.isNotEmpty ?? false ? '|' : ''} ${container.supplierPhone ?? ""}'
                      : 'BBD Limited'),
              _detailRow(
                "Date de reception",
                DateFormat.yMMMMEEEEd().format(container.createdAt!),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
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
                              final updatedContainer = await containerServices
                                  .getContainerDetails(container.id!);

                              setState(() {
                                container = updatedContainer;
                              });
                            }
                          },
                          label: const Text("Ajouter des colis"),
                          icon: const Icon(Icons.add),
                        )
                      : const Text(""),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher un colis...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: container.packages == null || container.packages!.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Pas de colis pour ce conteneur."),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          container.packages!;
                        },
                        displacement: 40,
                        color: Theme.of(context).primaryColor,
                        backgroundColor: Colors.white,
                        child: filteredPackages?.isEmpty == true
                            ? const Center(
                                child: Text(
                                  "Aucun colis ne correspond à votre recherche",
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: filteredPackages?.length ?? 0,
                                itemBuilder: (context, index) {
                                  final pkg = filteredPackages![index];

                                  return Dismissible(
                                    key: Key('${pkg.id}'),
                                    direction:
                                        container.status != Status.INPROGRESS
                                            ? DismissDirection.endToStart
                                            : DismissDirection.none,
                                    background: Container(
                                      padding: const EdgeInsets.only(
                                        right: 16,
                                      ),
                                      color: container.status != Status.RECEIVED
                                          ? Colors.red
                                          : Colors.grey,
                                      alignment: Alignment.centerRight,
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                    confirmDismiss: container.status !=
                                            Status.INPROGRESS
                                        ? (direction) async {
                                            final bool confirm =
                                                await showDialog(
                                              context: context,
                                              builder: (
                                                BuildContext context,
                                              ) {
                                                return AlertDialog(
                                                  backgroundColor: Colors.white,
                                                  title: const Text(
                                                    "Confirmation",
                                                  ),
                                                  content: const Text(
                                                    "Voulez-vous vraiment retirer ce colis du conteneur ?",
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                        context,
                                                      ).pop(
                                                        false,
                                                      ),
                                                      child: const Text(
                                                        "Annuler",
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                        context,
                                                      ).pop(true),
                                                      child: Text(
                                                        isLoading
                                                            ? "Suppression..."
                                                            : "Confirmer",
                                                        style: const TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );

                                            if (confirm != true) return false;

                                            try {
                                              final user = await authService
                                                  .getUserInfo();
                                              setState(() {
                                                isLoading = true;
                                              });
                                              final result = await packageServices
                                                  .removePackageFromContainer(
                                                packageId: pkg.id!,
                                                containerId: container.id!,
                                                userId: user!.id.toInt(),
                                              );

                                              if (result == "REMOVED") {
                                                setState(() {
                                                  container.packages!
                                                      .removeWhere(
                                                    (p) => p.id == pkg.id,
                                                  );
                                                });
                                                showSuccessTopSnackBar(
                                                  context,
                                                  "Colis retiré du conteneur",
                                                );
                                                return true;
                                              } else if (result ==
                                                  "PACKAGE_NOT_IN_CONTAINER") {
                                                showErrorTopSnackBar(
                                                  context,
                                                  "Le colis n'appartient pas à ce conteneur",
                                                );
                                              } else if (result ==
                                                  "CONTAINER_INPROGRESS") {
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
                                          _detailRow("Référence", pkg.ref),
                                          _detailRow(
                                            "Type d'expédition",
                                            pkg.expeditionType,
                                          ),
                                          _detailRow(
                                            "Client",
                                            '${pkg.clientName} ${pkg.clientPhone != null ? '| ${pkg.clientPhone}' : ''}',
                                          ),
                                          _detailRow(
                                            "Nombre de carton",
                                            pkg.itemQuantity.toString(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
              if (container.packages != null &&
                  container.packages!.isNotEmpty &&
                  container.status == Status.PENDING)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: confirmationButton(
                    subLabel: "Démarrage...",
                    icon: Icons.check,
                    label: "Démarrer la livraison",
                    isLoading: isLoading,
                    onPressed: () async {
                      final bool confirm = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Confirmer le démarrage"),
                            backgroundColor: Colors.white,
                            content: const Text(
                              "Voulez-vous vraiment démarrer la livraison de ce conteneur ?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("Annuler"),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text(
                                  isLoading ? "Démarrage..." : "Confirmer",
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),
                            ],
                          );
                        },
                      );

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
                        final result = await containerServices.startDelivery(
                            container.id!, user.id.toInt());

                        if (result == "SUCCESS") {
                          final updatedContainer = await containerServices
                              .getContainerDetails(container.id!);
                          Navigator.of(context).pop(updatedContainer);
                          if (onContainerUpdated != null) {
                            onContainerUpdated(updatedContainer);
                          }
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
                  ),
                )
              else if (container.status == Status.INPROGRESS)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: confirmationButton(
                    subLabel: "Changement de statut...",
                    icon: Icons.check,
                    label: "Arrivé à destination",
                    isLoading: isLoading,
                    onPressed: () async {
                      final bool confirm = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title:
                                const Text("Confirmer l'arrivée du conteneur"),
                            backgroundColor: Colors.white,
                            content: const Text(
                              "Voulez-vous vraiment confirmer que le conteneur est arrivé à destination ?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("Annuler"),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text(
                                  isLoading
                                      ? "Changement de statut..."
                                      : "Confirmer",
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),
                            ],
                          );
                        },
                      );

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
                        final result = await containerServices.confirmReceiving(
                            container.id!, user.id.toInt());

                        if (result == "SUCCESS") {
                          final updatedContainer = await containerServices
                              .getContainerDetails(container.id!);
                          Navigator.of(context).pop(updatedContainer);
                          if (onContainerUpdated != null) {
                            onContainerUpdated(updatedContainer);
                          }
                          showSuccessTopSnackBar(
                            context,
                            "Conteneur confirmé à destination !",
                          );
                        } else if (result == "NO_PACKAGE_FOR_DELIVERY") {
                          showErrorTopSnackBar(
                            context,
                            "Impossible de confirmer la réception, pas de colis dans le conteneur.",
                          );
                        } else if (result == "CONTAINER_NOT_IN_PROGRESS") {
                          showErrorTopSnackBar(
                            context,
                            "Le conteneur n'est pas en status INPROGRESS.",
                          );
                        }
                      } catch (e) {
                        showErrorTopSnackBar(
                          context,
                          "Erreur lors de la reception du conteneur",
                        );
                      } finally {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}
