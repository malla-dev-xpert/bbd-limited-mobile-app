import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/harbor_services.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

Future<bool?> showAddHarborModal(BuildContext context) async {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final AuthService authService = AuthService();
  final HarborServices harborServices = HarborServices();

  bool isLoading = false;

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Ajouter un nouveau port",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.clear, color: Colors.black),
                      ),
                    ],
                  ),
                  // const SizedBox(height: 40),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildTextField(
                        controller: nameController,
                        label: "Le nom du port",
                        icon: Icons.local_shipping,
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Veuillez entrer un nom'
                                    : null,
                      ),
                      const SizedBox(height: 10),

                      buildTextField(
                        controller: locationController,
                        label: "L'adresse du port",
                        icon: Icons.maps_home_work,
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'L\'adresse du port est requise.'
                                    : null,
                      ),

                      const SizedBox(height: 30),

                      confirmationButton(
                        isLoading: isLoading,
                        onPressed: () async {
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

                            final result = await harborServices.create(
                              nameController.text,
                              locationController.text,
                              user.id,
                            );

                            if (result == "NAME_EXIST") {
                              setState(() => isLoading = false);
                              showErrorTopSnackBar(
                                context,
                                "Le nom '${nameController.text}' existe déjà.",
                              );
                              return;
                            } else if (result == "CREATED") {
                              setState(() {
                                isLoading = false;
                              });

                              Navigator.pop(context, true);
                              showSuccessTopSnackBar(
                                context,
                                "Nouveau port ajouté avec succès !",
                              );
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              showErrorTopSnackBar(
                                context,
                                "Une erreur est survenue, veuillez réessayer.",
                              );
                            });
                          }
                        },
                        label: "Enregistrer",
                        icon: Icons.check_circle_outline_rounded,
                        subLabel: "Enregistrement...",
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
