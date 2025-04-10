import 'dart:async';

import 'package:bbd_limited/core/services/devises_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

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

  final ScrollController _scrollController = ScrollController();
  late final KeyboardVisibilityController _keyboardVisibilityController;
  late final StreamSubscription<bool> _keyboardSubscription;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _keyboardVisibilityController = KeyboardVisibilityController();

    _keyboardSubscription = _keyboardVisibilityController.onChange.listen((
      visible,
    ) {
      if (!visible) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _create(BuildContext parentContext) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String success = await authService.create(
      _nameController.text,
      _codeController.text,
      double.tryParse(_rateController.text) ?? 0.0,
    );

    setState(() {
      _isLoading = false;
      if (success == "CREATED") {
        Navigator.pop(parentContext); // Ferme le BottomSheet
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(content: Text("Devise ajoutée avec succès !")),
        );
        _nameController.clear();
        _codeController.clear();
        _rateController.clear();
      } else if (success == "CODE_EXIST") {
        setState(() {
          _errorMessage = "Le code existe déjà. Veuillez en choisir un autre.";
        });
      } else {
        setState(() {
          _errorMessage = "Une erreur est survenue. Veuillez réessayer.";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          "Gestion des devises",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A1E49),
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
                                _codeController.clear();
                                _rateController.clear();
                                _nameController.clear();
                                _errorMessage = null;
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
                          autocorrect: false,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.attach_money,
                              color: Colors.black,
                            ),
                            labelText: 'Nom de la devise',
                            hintText: 'Ex: Dollar US',
                            fillColor: Colors.white,
                            filled: true,
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
                          autocorrect: false,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.abc,
                              color: Colors.black,
                            ),
                            labelText: 'Code',
                            hintText: 'Ex: USD, EUR, GBP',
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
                          autocorrect: false,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.percent,
                              color: Colors.black,
                            ),
                            labelText: 'Taux de change',
                            hintText: 'Ex: 545.0',
                            fillColor: Colors.white,
                            filled: true,
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
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),

                        const SizedBox(height: 10),

                        ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () {
                                    if (_formKey.currentState!.validate()) {
                                      _create(context);
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: const Color(0xFF1A1E49),
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
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
      body: SingleChildScrollView(
        controller: _scrollController,
        physics:
            keyboardVisible
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
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
        ),
      ),
    );
  }
}
