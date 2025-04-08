import 'package:flutter/material.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

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
                  height: 450,
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
                        decoration: InputDecoration(
                          labelText: 'Nom de la devise',
                          hintText: 'Ex: Dollar US',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Code',
                          hintText: 'Ex: USD, EUR, GBP',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Taux de change',
                          hintText: 'Ex: 545.0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          // Logique pour enregistrer la devise ici
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: const Color(0xFF13084F),
                        ),
                        child: const Text(
                          'Enregistrer',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
