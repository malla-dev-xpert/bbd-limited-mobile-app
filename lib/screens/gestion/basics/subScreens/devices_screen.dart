import 'package:bbd_limited/core/services/devises_service.dart';
import 'package:flutter/material.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DeviseState();
}

class _DeviseState extends State<DevicesScreen> {
  final _formKey = GlobalKey<FormState>();
  final DeviseServices authService = DeviseServices();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  void _create() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String success = await authService.create(
      _nameController.text,
      _codeController.text,
      double.parse(_rateController.text),
    );

    setState(() {
      _isLoading = false;
      if (success == "CREATED") {
        _nameController.clear();
        _codeController.clear();
        _rateController.clear();
        Navigator.pop(context); //femer le bottom shit
      } else if (success == "CODE_EXIST") {
        _errorMessage = "Le code existe déjà. Veuillez en choisir un autre.";
      } else {
        _errorMessage = "Une erreur est survenue. Veuillez réessayer.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Gestion des devises",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF13084F),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF13084F),
        tooltip: 'Add New devise',
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            isScrollControlled: true, // Ajouté pour gérer le clavier
            builder: (BuildContext context) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.of(
                        context,
                      ).viewInsets.bottom, // Gère le clavier
                  left: 30,
                  right: 30,
                  top: 30,
                ),
                child: Container(
                  height: 500,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: const Text(
                                  'Ajouter une nouvelle devise',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1,
                                  ),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.close_rounded, size: 30),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nom de la devise',
                            hintText: 'Ex: Dollar US',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez definir un nom';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            labelText: 'Code',
                            hintText: 'Ex: USD, EUR, GBP',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez definir le code';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _rateController,
                          decoration: InputDecoration(
                            labelText: 'Taux de change',
                            hintText: 'Ex: 545.0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez definir le taux de change actuel.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 40),
                        // Afficher les erreur de connexion
                        if (_errorMessage != null)
                          Center(
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),

                        const SizedBox(height: 10),

                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _create();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: const Color(0xFF13084F),
                          ),
                          child:
                              _isLoading
                                  ? CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                  : Text(
                                    'Enregistrer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Rechercher',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
      ),
    );
  }
}
