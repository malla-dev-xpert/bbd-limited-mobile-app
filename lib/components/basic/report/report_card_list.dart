// card_data.dart
import 'package:flutter/material.dart';

class ReportCardData {
  final IconData icon;
  final String title;
  final int quantity;

  ReportCardData({
    required this.icon,
    required this.title,
    required this.quantity,
  });
}

List<ReportCardData> reportCardDataList = [
  ReportCardData(
    icon: Icons.monetization_on_rounded,
    title: 'Total des partenaires',
    quantity: 100,
  ),
  ReportCardData(
    icon: Icons.warehouse,
    title: 'Total des transporteurs',
    quantity: 200,
  ),
  ReportCardData(
    icon: Icons.monetization_on_rounded,
    title: 'Total des ports',
    quantity: 300,
  ),
];
