import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

Future<bool?> showAddItemsModal(BuildContext context, int packageId) async {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final List<Map<String, dynamic>> localItems = [];
  final AuthService authService = AuthService();
  final PackageServices packageServices = PackageServices();
  final ItemServices itemServices = ItemServices();
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
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Ajouter des articles au colis",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.clear, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Description input
                  buildTextField(
                    controller: descriptionController,
                    label: "Description de l'article",
                    icon: Icons.description,
                    validator:
                        (v) =>
                            v == null || v.isEmpty
                                ? 'Veuillez entrer la description'
                                : null,
                  ),
                  const SizedBox(height: 10),

                  // Quantity input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      Expanded(
                        child: buildTextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          label: "Quantité",
                          icon: Icons.numbers,
                          validator:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? 'Veuillez entrer la quantité'
                                      : null,
                        ),
                      ),

                      // Ajouter button
                      ElevatedButton.icon(
                        onPressed: () {
                          final description = descriptionController.text.trim();
                          final quantity = double.tryParse(
                            quantityController.text.trim(),
                          );

                          if (description.isNotEmpty && quantity != null) {
                            setState(() {
                              localItems.add({
                                'description': description,
                                'quantity': quantity,
                              });
                              descriptionController.clear();
                              quantityController.clear();
                            });
                          }
                        },
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text(
                          "Ajouter",
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
                  const SizedBox(height: 10),

                  const SizedBox(height: 10),

                  // Liste des articles ajoutés
                  if (localItems.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: localItems.length,
                        itemBuilder: (context, index) {
                          final item = localItems[index];
                          return ListTile(
                            title: Text(item['description']),
                            subtitle: Text("Quantité : ${item['quantity']}"),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  localItems.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "Aucun article ajouté.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Boutons d'action
                  if (localItems.isNotEmpty)
                    confirmationButton(
                      isLoading: isLoading,
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });

                        final user = await authService.getUserInfo();

                        if (user == null) {
                          setState(() => isLoading = false);
                          showErrorTopSnackBar(
                            context,
                            "Erreur: Utilisateur non connecté",
                          );
                          return;
                        }

                        if (localItems.isEmpty) {
                          setState(() => isLoading = false);
                          showErrorTopSnackBar(
                            context,
                            "Erreur: Aucun article à ajouter",
                          );
                          return;
                        }

                        await packageServices.addItemsToPackage(
                          packageId,
                          localItems,
                          user.id.toInt(),
                        );

                        setState(() {
                          isLoading = false;
                          localItems.clear();
                          itemServices.findByPackageId(packageId);
                        });

                        Navigator.pop(context, true);
                        showSuccessTopSnackBar(
                          context,
                          "Articles ajoutés avec succès !",
                        );
                      },
                      label: "Confirmer",
                      icon: Icons.check_circle_outline_rounded,
                      subLabel: "Confirmation...",
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
