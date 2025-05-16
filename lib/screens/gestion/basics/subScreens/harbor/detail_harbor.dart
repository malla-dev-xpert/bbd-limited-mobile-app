import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/harbor_services.dart';
import 'package:bbd_limited/models/harbor.dart';
import 'package:bbd_limited/screens/gestion/basics/subScreens/harbor/widgets/add_container_to_harbor.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HarborDetailPage extends StatefulWidget {
  final Harbor harbor;

  const HarborDetailPage({required this.harbor});

  @override
  State<HarborDetailPage> createState() => _HarborDetailPageState();
}

class _HarborDetailPageState extends State<HarborDetailPage> {
  @override
  Widget build(BuildContext context) {
    String formattedDate =
        widget.harbor.createdAt != null
            ? DateFormat.yMMMMEEEEd().format(widget.harbor.createdAt!)
            : 'Date non disponible';
    final AuthService authService = AuthService();
    final HarborServices _harborServices = HarborServices();
    final ContainerServices _containerServices = ContainerServices();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150.0,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  widget.harbor.name ?? 'Port sans nom',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  maxLines: 2,
                ),
              ),
              centerTitle: true,
              background: Hero(
                tag: 'portImage-${widget.harbor.id}',
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.asset(
                        "assets/images/ports.jpg",
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        color: Colors.black.withOpacity(0.6),
                      ),
                      alignment: Alignment.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Informations générales du port",
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 5),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF7F78AF),
                          style: BorderStyle.solid,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.local_shipping,
                                size: 20,
                                color: Color(0xFF7F78AF),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Nom du port : ${widget.harbor.name ?? 'Non spécifié'}",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.maps_home_work,
                                size: 20,
                                color: Color(0xFF7F78AF),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Adresse : ${widget.harbor.location ?? 'Non spécifiée'}",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                size: 20,
                                color: Color(0xFF7F78AF),
                              ),
                              const SizedBox(width: 10),
                              Text("Date de création : $formattedDate"),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.numbers,
                                size: 20,
                                color: Color(0xFF7F78AF),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Nombre de conteneur : ${widget.harbor.containers?.where((c) => c.status != Status.DELETE && c.status != Status.RETRIEVE).length ?? 0}",
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () {},
                                label: const Text("Modifier"),
                                icon: const Icon(Icons.edit),
                              ),
                              TextButton.icon(
                                onPressed: () {},
                                label: const Text(
                                  "Supprimer",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.harbor.containers?.isNotEmpty ?? false)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const TextButton(
                            onPressed: null,
                            child: Text(
                              "La liste des conteneurs",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          widget.harbor.containers!.isNotEmpty
                              ? TextButton.icon(
                                onPressed: () async {
                                  final selectedContainers =
                                      await showAddContainerToHarborDialog(
                                        context,
                                        widget.harbor.id,
                                        _containerServices,
                                      );

                                  if (selectedContainers != null &&
                                      selectedContainers.isNotEmpty) {
                                    try {
                                      // Afficher un indicateur de chargement si nécessaire
                                      setState(() {});

                                      // Récupérer les nouvelles données
                                      final updatedHarbor =
                                          await _harborServices
                                              .getHarborDetails(
                                                widget.harbor.id,
                                              );

                                      // Mettre à jour l'état
                                      if (mounted) {
                                        setState(() {
                                          widget.harbor.containers =
                                              updatedHarbor.containers;
                                        });
                                      }

                                      // Afficher un message de succès
                                      showSuccessTopSnackBar(
                                        context,
                                        "Conteneurs ajoutés avec succès",
                                      );
                                    } catch (e) {
                                      showErrorTopSnackBar(
                                        context,
                                        "Erreur lors de la mise à jour",
                                      );
                                    }
                                  }
                                },
                                label: const Text("Embarquer"),
                                icon: const Icon(Icons.add),
                              )
                              : Text(""),
                        ],
                      ),
                    const SizedBox(height: 10),
                    if (widget.harbor.containers == null ||
                        widget.harbor.containers!.isEmpty)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Pas de conteneurs pour ce port."),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final selectedContainers =
                                    await showAddContainerToHarborDialog(
                                      context,
                                      widget.harbor.id,
                                      _containerServices,
                                    );

                                if (selectedContainers != null &&
                                    selectedContainers.isNotEmpty) {
                                  try {
                                    // Afficher un indicateur de chargement si nécessaire
                                    setState(() {});

                                    // Récupérer les nouvelles données
                                    final updatedHarbor = await _harborServices
                                        .getHarborDetails(widget.harbor.id);

                                    // Mettre à jour l'état
                                    if (mounted) {
                                      setState(() {
                                        widget.harbor.containers =
                                            updatedHarbor.containers;
                                      });
                                    }

                                    // Afficher un message de succès
                                    showSuccessTopSnackBar(
                                      context,
                                      "Conteneurs ajoutés avec succès",
                                    );
                                  } catch (e) {
                                    showErrorTopSnackBar(
                                      context,
                                      "Erreur lors de la mise à jour",
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                "Embarquer un conteneur",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7F78AF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children:
                            widget.harbor.containers!
                                .where(
                                  (element) =>
                                      element.status != Status.DELETE &&
                                      element.status != Status.RETRIEVE,
                                )
                                .map((item) {
                                  return Dismissible(
                                    key: Key(
                                      item.id?.toString() ??
                                          DateTime.now().toString(),
                                    ),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      padding: const EdgeInsets.only(right: 16),
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                    confirmDismiss: (direction) async {
                                      try {
                                        final user =
                                            await authService.getUserInfo();
                                        if (user == null) {
                                          showErrorTopSnackBar(
                                            context,
                                            "Erreur: Utilisateur non connecté",
                                          );
                                          return false;
                                        }

                                        await _harborServices
                                            .retrieveContainerToHarbor(
                                              widget.harbor.containers!.indexOf(
                                                item,
                                              ),
                                              user.id.toInt(),
                                              widget.harbor.id,
                                            );

                                        showSuccessTopSnackBar(
                                          context,
                                          "Conteneur retiré avec succès",
                                        );
                                        return true;
                                      } catch (e) {
                                        showErrorTopSnackBar(
                                          context,
                                          "Erreur lors de la suppression",
                                        );
                                        return false;
                                      }
                                    },
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.inventory_2_rounded,
                                        color:
                                            item.isAvailable == true
                                                ? Colors.green
                                                : Colors.grey,
                                      ),
                                      title: Text(
                                        item.reference ?? 'Sans référence',
                                      ),
                                      trailing: Text(
                                        item.isAvailable == true
                                            ? "Disponible"
                                            : "Indisponible",
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
