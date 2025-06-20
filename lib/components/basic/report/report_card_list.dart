// card_data.dart
import 'package:flutter/material.dart';

class ReportCardData {
  final String title;
  final String value;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  ReportCardData({
    required this.title,
    required this.value,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });
}

List<ReportCardData> reportCardDataList = [
  ReportCardData(
    title: 'Balance Actuelle',
    value: '4 1260.50',
    backgroundColor: Colors.amber[800]!, // Orange
    textColor: Colors.white,
    icon: Icons.wallet,
  ),
  ReportCardData(
    title: 'Total des dettes',
    value: '4 320.50',
    backgroundColor: const Color(0xFF1A1E49), // Blue
    textColor: Colors.white,
    icon: Icons.currency_yen_rounded,
  ),
];
