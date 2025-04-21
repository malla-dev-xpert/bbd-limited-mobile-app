import 'package:bbd_limited/components/confirm_btn.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/core/services/package_services.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

Future<bool?> showAddPackageModal(BuildContext context, int warehouseId) async {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController refController = TextEditingController();
  final TextEditingController dimensionController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final List<Map<String, dynamic>> localItems = [];
  final AuthService authService = AuthService();
  final PackageServices packageServices = PackageServices();
  final ItemServices itemServices = ItemServices();
  final PartnerServices partnerServices = PartnerServices();
  List<Partner> clients = [];
  bool isLoading = false;
  Partner? selectedClient;

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: StatefulBuilder(
          builder: (context, setState) {
            Future<void> loadClients() async {
              try {
                final data = await partnerServices.fetchPartnersByType(
                  'CLIENT',
                  page: 0,
                );

                setState(() {
                  clients = data;
                  isLoading = false;
                });
              } catch (e, stackTrace) {
                setState(() => isLoading = false);
                showErrorTopSnackBar(
                  context,
                  "Erreur lors du chargement des partenaires",
                );
              }
            }

            if (clients.isEmpty && !isLoading) {
              isLoading = true;
              loadClients();
            }

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
                        "Ajouter un nouveau colis",
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
                        controller: refController,
                        label: "Libellé du colis",
                        icon: Icons.description,
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Veuillez entrer le libellé'
                                    : null,
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        spacing: 10,
                        children: [
                          Expanded(
                            child: buildTextField(
                              controller: weightController,
                              label: "Le poids du colis",
                              keyboardType: TextInputType.number,
                              icon: Icons.numbers_rounded,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'Le poids du colis est requis'
                                          : null,
                            ),
                          ),
                          Expanded(
                            child: buildTextField(
                              controller: dimensionController,
                              label: "La dimension du colis",
                              icon: Icons.line_weight,
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'La dimension du colis est requise'
                                          : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      DropdownButtonFormField<Partner>(
                        isExpanded: true,
                        value: selectedClient,
                        onChanged: (Partner? value) {
                          setState(() {
                            selectedClient = value;
                          });
                        },
                        items:
                            clients.map((client) {
                              return DropdownMenuItem<Partner>(
                                value: client,
                                child: Row(
                                  children: [
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${client.firstName} ${client.lastName} | ${client.phoneNumber}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        decoration: InputDecoration(
                          labelText: "Choisir un client",
                          prefixIcon: Icon(Icons.person, color: Colors.black),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        dropdownColor: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Ajouter des articles au colis"),
                      const SizedBox(height: 5),
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
                              label: "Quantité",
                              keyboardType: TextInputType.number,
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
                              final description =
                                  descriptionController.text.trim();
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

                      // Liste des articles ajoutés
                      if (localItems.isNotEmpty)
                        SizedBox(
                          height: 200, // ← ajuste à ta convenance
                          child: ListView.builder(
                            itemCount: localItems.length,
                            itemBuilder: (context, index) {
                              final item = localItems[index];
                              return ListTile(
                                title: Text(item['description']),
                                subtitle: Text(
                                  "Quantité : ${item['quantity']}",
                                ),
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

                              if (selectedClient == null) {
                                setState(() => isLoading = false);
                                showErrorTopSnackBar(
                                  context,
                                  "Veuillez sélectionner un client.",
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

                              final packageId = await packageServices.create(
                                refController.text,
                                dimensionController.text,
                                double.parse(weightController.text),
                                user.id,
                                warehouseId,
                                selectedClient!.id.toInt(),
                              );

                              if (packageId == null) {
                                setState(() => isLoading = false);
                                showErrorTopSnackBar(
                                  context,
                                  "Erreur: Référence déjà utilisée.",
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
                                "Colis ajoutés avec succès !",
                              );
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
