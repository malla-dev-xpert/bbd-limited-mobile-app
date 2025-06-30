// card_data.dart

import 'package:flutter/material.dart';

class CardData {
  final IconData icon;
  final String title;
  final Color backgroundColor;
  final Color iconColor;
  final Color titleColor;
  final void Function(BuildContext context) onPressed;
  final String? description;

  CardData({
    required this.icon,
    required this.title,
    required this.backgroundColor,
    required this.iconColor,
    required this.titleColor,
    required this.onPressed,
    this.description,
  });
}

List<CardData> cardDataList = [
  CardData(
    icon: Icons.inventory_2,
    title: 'Gestion des colis',
    backgroundColor: Colors.grey[50]!,
    iconColor: const Color(0xFF13084F),
    titleColor: const Color(0xFF13084F),
    onPressed: (context) {
      Navigator.of(context).pushNamed('/package');
    },
    description: 'Consultez, ajoutez et gérez tous les colis de vos clients.',
  ),
  CardData(
    icon: Icons.person_3_rounded,
    title: 'Gestion des comptes clients',
    backgroundColor: Colors.grey[50]!,
    iconColor: const Color(0xFF13084F),
    titleColor: const Color(0xFF13084F),
    onPressed: (context) {
      Navigator.of(context).pushNamed('/partners');
    },
    description: 'Accédez aux informations et opérations des clients.',
  ),
  CardData(
    icon: Icons.warehouse,
    title: 'Gestion des entrepôts',
    backgroundColor: Colors.grey[50]!,
    iconColor: const Color(0xFF13084F),
    titleColor: const Color(0xFF13084F),
    onPressed: (context) {
      Navigator.of(context).pushNamed('/warehouse');
    },
    description: 'Visualisez et organisez vos entrepôts de stockage.',
  ),
  CardData(
    icon: Icons.monetization_on_rounded,
    title: 'Gestion des devises',
    backgroundColor: Colors.grey[50]!,
    iconColor: const Color(0xFF13084F),
    titleColor: const Color(0xFF13084F),
    onPressed: (context) {
      Navigator.of(context).pushNamed('/devises');
    },
    description: 'Ajoutez ou modifiez les devises utilisées dans le système.',
  ),
  CardData(
    icon: Icons.info,
    title: 'Gestion des ports',
    backgroundColor: Colors.grey[50]!,
    iconColor: const Color(0xFF13084F),
    titleColor: const Color(0xFF13084F),
    onPressed: (context) {
      Navigator.of(context).pushNamed('/harbor');
    },
    description:
        'Référencez et gérez les ports d’embarquement et de livraison.',
  ),
  CardData(
    icon: Icons.view_quilt,
    title: 'Gestion des conteneurs',
    backgroundColor: Colors.grey[50]!,
    iconColor: const Color(0xFF13084F),
    titleColor: const Color(0xFF13084F),
    onPressed: (context) {
      Navigator.of(context).pushNamed('/container');
    },
    description: 'Suivez et administrez vos conteneurs de transport.',
  ),
];
