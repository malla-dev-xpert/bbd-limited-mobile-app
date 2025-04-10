// card_data.dart

import 'package:flutter/material.dart';

class CardData {
  final IconData icon;
  final String title;
  final String description;
  final Color backgroundColor;
  final Color iconColor;
  final Color titleColor;
  final Color descriptionColor;
  final void Function(BuildContext context) onPressed;

  CardData({
    required this.icon,
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.iconColor,
    required this.titleColor,
    required this.descriptionColor,
    required this.onPressed,
  });
}

List<CardData> cardDataList = [
  CardData(
    icon: Icons.monetization_on_rounded,
    title: 'Gestion des devises',
    description:
        'Paramétrage des monnaies utilisées pour les transactions internationales.',
    backgroundColor: Colors.grey[50]!,
    iconColor: const Color(0xFF13084F),
    titleColor: const Color(0xFF13084F),
    descriptionColor: Colors.black54,
    onPressed: (context) {
      Navigator.of(context).pushNamed('/devises');
    },
  ),
  CardData(
    icon: Icons.warehouse,
    title: 'Gestion des entrepôts',
    description:
        'Enregistrement et suivi des entrepôts pour le stockage des marchandises.',
    backgroundColor: Colors.grey[50]!,
    iconColor: const Color(0xFF13084F),
    titleColor: const Color(0xFF13084F),
    descriptionColor: Colors.black54,
    onPressed: (context) {
      Navigator.of(context).pushNamed('/home');
    },
  ),
  CardData(
    icon: Icons.info,
    title: 'Gestion des ports',
    description: 'Ajout et gestion des informations spécifiques aux ports',
    backgroundColor: Colors.grey[50]!,
    iconColor: const Color(0xFF13084F),
    titleColor: const Color(0xFF13084F),
    descriptionColor: Colors.black54,
    onPressed: (context) {
      Navigator.of(context).pushNamed('/home');
    },
  ),
  CardData(
    icon: Icons.directions_transit,
    title: 'Gestion des transporteurs',
    description:
        'Suivi des partenaires logistiques et gestion des prestataires de transport.',
    backgroundColor: Colors.grey[50]!,
    iconColor: const Color(0xFF13084F),
    titleColor: const Color(0xFF13084F),
    descriptionColor: Colors.black54,
    onPressed: (context) {
      Navigator.of(context).pushNamed('/home');
    },
  ),
  CardData(
    icon: Icons.monetization_on_rounded,
    title: 'Gestion des devises',
    description:
        'Paramétrage des monnaies utilisées pour les transactions internationales.',
    backgroundColor: Colors.grey[50]!,
    iconColor: const Color(0xFF13084F),
    titleColor: const Color(0xFF13084F),
    descriptionColor: Colors.black54,
    onPressed: (context) {
      Navigator.of(context).pushNamed('/home');
    },
  ),
  CardData(
    icon: Icons.warehouse,
    title: 'Gestion des entrepôts',
    description:
        'Enregistrement et suivi des entrepôts pour le stockage des marchandises.',
    backgroundColor: Colors.grey[50]!,
    iconColor: const Color(0xFF13084F),
    titleColor: const Color(0xFF13084F),
    descriptionColor: Colors.black54,
    onPressed: (context) {
      Navigator.of(context).pushNamed('/home');
    },
  ),
  CardData(
    icon: Icons.info,
    title: 'Gestion des ports',
    description: 'Ajout et gestion des informations spécifiques aux ports',
    backgroundColor: Colors.grey[50]!,
    iconColor: const Color(0xFF13084F),
    titleColor: const Color(0xFF13084F),
    descriptionColor: Colors.black54,
    onPressed: (context) {
      Navigator.of(context).pushNamed('/home');
    },
  ),
  CardData(
    icon: Icons.directions_transit,
    title: 'Gestion des transporteurs',
    description:
        'Suivi des partenaires logistiques et gestion des prestataires de transport.',
    backgroundColor: Colors.grey[50]!,
    iconColor: const Color(0xFF13084F),
    titleColor: const Color(0xFF13084F),
    descriptionColor: Colors.black54,
    onPressed: (context) {
      Navigator.of(context).pushNamed('/home');
    },
  ),
];
