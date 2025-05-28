import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/harbor_services.dart';
import 'package:bbd_limited/models/harbor.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/components/confirm_btn.dart';

Future<bool?> showAddHarborModal(BuildContext context, {Harbor? harbor}) async {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final AuthService authService = AuthService();
  final HarborServices harborServices = HarborServices();

  bool isLoading = false;

  // Si on est en mode édition, on pré-remplit les champs
  if (harbor != null) {
    nameController.text = harbor.name ?? '';
    locationController.text = harbor.location ?? '';
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        harbor == null ? 'Ajouter un port' : 'Modifier le port',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildTextField(
                            controller: nameController,
                            label: "Nom du port",
                            icon: Icons.local_shipping),
                        const SizedBox(height: 16),
                        buildTextField(
                            controller: locationController,
                            label: "Adresse",
                            icon: Icons.map),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: confirmationButton(
                      isLoading: isLoading,
                      onPressed: () async {
                        if (!isLoading) {
                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final user = await authService.getUserInfo();

                            if (user == null) {
                              setState(() => isLoading = false);
                              showErrorTopSnackBar(
                                context,
                                "Erreur: Utilisateur non connecté",
                              );
                              return;
                            }

                            if (nameController.text.isEmpty) {
                              setState(() => isLoading = false);
                              showErrorTopSnackBar(
                                context,
                                "Veuillez entrer un nom pour le port.",
                              );
                              return;
                            }

                            if (locationController.text.isEmpty) {
                              setState(() => isLoading = false);
                              showErrorTopSnackBar(
                                context,
                                "Veuillez entrer une adresse pour le port.",
                              );
                              return;
                            }

                            if (harbor == null) {
                              // Création d'un nouveau port
                              final result = await harborServices.create(
                                nameController.text,
                                locationController.text,
                                user.id,
                              );

                              if (result == "CREATED") {
                                showSuccessTopSnackBar(
                                  context,
                                  "Port créé avec succès",
                                );
                                Navigator.pop(context, true);
                              } else if (result == "NAME_EXIST") {
                                showErrorTopSnackBar(
                                  context,
                                  "Ce nom de port existe déjà",
                                );
                              }
                            } else {
                              // Mise à jour d'un port existant
                              final result = await harborServices.update(
                                harbor.id,
                                nameController.text,
                                locationController.text,
                                user.id,
                              );

                              if (result == "UPDATED") {
                                showSuccessTopSnackBar(
                                  context,
                                  "Port mis à jour avec succès",
                                );
                                Navigator.pop(context, true);
                              } else if (result == "NAME_EXIST") {
                                showErrorTopSnackBar(
                                  context,
                                  "Ce nom de port existe déjà",
                                );
                              }
                            }
                          } catch (e) {
                            showErrorTopSnackBar(
                              context,
                              "Erreur: ${e.toString()}",
                            );
                          } finally {
                            setState(() => isLoading = false);
                          }
                        }
                      },
                      label: harbor == null ? "Enregistrer" : "Modifier",
                      icon: harbor == null ? Icons.check_circle : Icons.edit,
                      subLabel: harbor == null
                          ? "Enregistrement..."
                          : "Modification...",
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );
    },
  );
}
