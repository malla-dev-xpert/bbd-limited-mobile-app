import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/harbor_services.dart';
import 'package:bbd_limited/models/harbor.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HarborDetailPage extends StatelessWidget {
  final Harbor harbor;

  const HarborDetailPage({required this.harbor});

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat.yMMMMEEEEd().format(harbor.createdAt!);
    final AuthService authService = AuthService();
    final HarborServices _harborServices = HarborServices();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150.0,
            pinned: true,
            iconTheme: IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  harbor.name!,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  maxLines: 2,
                ),
              ),
              centerTitle: true,
              background: Hero(
                tag: 'portImage-${harbor.id}',
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
                  spacing: 5,
                  children: [
                    Text(
                      "Informations générales du port",
                      style: TextStyle(fontSize: 14),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF7F78AF),
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            spacing: 10,
                            children: [
                              Icon(
                                Icons.local_shipping,
                                size: 20,
                                color: const Color(0xFF7F78AF),
                              ),
                              Expanded(
                                child: Text("Nom du port : ${harbor.name!}"),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            spacing: 10,
                            children: [
                              Icon(
                                Icons.maps_home_work,
                                size: 20,
                                color: const Color(0xFF7F78AF),
                              ),
                              Expanded(
                                child: Text("Adresse : ${harbor.location!}"),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            spacing: 10,
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 20,
                                color: const Color(0xFF7F78AF),
                              ),
                              Text("Date de création : $formattedDate"),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            spacing: 10,
                            children: [
                              Icon(
                                Icons.numbers,
                                size: 20,
                                color: const Color(0xFF7F78AF),
                              ),
                              Text(
                                "Nombre de conteneur : ${harbor.containers!.where((c) => c.status != Status.DELETE && c.status != Status.RETRIEVE).length}",
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.delete, color: Colors.white),
                            label: Text(
                              "Supprimer ce port",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Ajoute d'autres infos ici
            ]),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    harbor.containers!.isNotEmpty
                        ? Text("La liste des conteneurs")
                        : Text(""),
                    const SizedBox(height: 10),
                    harbor.containers == null || harbor.containers!.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Pas de conteneurs pour ce port."),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: Icon(Icons.add, color: Colors.white),
                                label: Text(
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
                        : Column(
                          children:
                              harbor.containers!
                                  .where(
                                    (element) =>
                                        element.status != Status.DELETE ||
                                        element.status == Status.RETRIEVE,
                                  )
                                  .map((item) {
                                    return Dismissible(
                                      key: Key(harbor.id.toString()),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        padding: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        child: Icon(
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
                                            return;
                                          }

                                          await _harborServices
                                              .retrieveContainerToHarbor(
                                                harbor.containers!.indexOf(
                                                  item,
                                                ),
                                                user.id.toInt(),
                                                harbor.id,
                                              );

                                          // setState(() {
                                          //   _allPackages.removeWhere(
                                          //     (d) => d.id == pkg.id,
                                          //   );
                                          //   _filteredPackages = List.from(
                                          //     _allPackages,
                                          //   );
                                          // });

                                          showSuccessTopSnackBar(
                                            context,
                                            "Conteneur retiré avec succès",
                                          );
                                        } catch (e) {
                                          showErrorTopSnackBar(
                                            context,
                                            "Erreur lors de la suppression",
                                          );
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
                                        title: Text(item.reference!),
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
