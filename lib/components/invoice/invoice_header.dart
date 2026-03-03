import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:intl/intl.dart';

/// Widget réutilisable pour l'en-tête de facture
/// Aligné sur le design fourni avec logo, informations entreprise et détails facture
class InvoiceHeader extends StatelessWidget {
  final String invoiceNumber;
  final DateTime invoiceDate;
  final String? customerName;
  final String? customerPhone;
  final String? customerRegisterNo;
  final String? commissionnaireName;
  final String? commissionnairePhone;
  final String currency;
  final double exchangeRate;
  final int? totalPurchaseOrder;
  final double? montantVerser;
  final double? montantRestant;
  final Uint8List? logoBytes;
  final bool isVersement; // true pour versement, false pour achat

  const InvoiceHeader({
    Key? key,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.customerName,
    this.customerPhone,
    this.customerRegisterNo,
    this.commissionnaireName,
    this.commissionnairePhone,
    required this.currency,
    this.exchangeRate = 1.0,
    this.totalPurchaseOrder,
    this.montantVerser,
    this.montantRestant,
    this.logoBytes,
    this.isVersement = false, // Par défaut, c'est un achat
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    const primaryColor = Color(0xFF1A1E49); // Couleur principale du projet

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec design de carte de visite
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: primaryColor, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section gauche avec fond dégradé bleu clair
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom de l'entreprise
                      Text(
                        'BBD LIMITED',
                        style: AppTextSize.displayStyle(context,
                                color: primaryColor, fontWeight: FontWeight.w900)
                            .copyWith(
                                letterSpacing: 1.5,
                                fontStyle: FontStyle.italic,
                                shadows: const [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                    color: Colors.black26,
                                  ),
                                ]),
                      ),
                      const SizedBox(height: 12),

                      // Adresse en rouge
                      Text(
                        '1Floor, Building 10,Room 102, Zhao Zhai san qu, Yiwu, Zhejiang, China',
                        style: AppTextSize.captionStyle(context,
                            color: Colors.red)
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '中国 浙江省义乌市赵宅3区10栋1单元102',
                        style: AppTextSize.captionStyle(context,
                            color: Colors.red)
                            .copyWith(fontWeight: FontWeight.w500),
                      ),

                      // Ligne séparatrice bleu foncé
                      const SizedBox(height: 12),
                      Container(
                        height: 2,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 12),

                      // Informations de contact
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contact :',
                                  style: AppTextSize.captionStyle(context,
                                      color: Colors.black87)
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '0086 18678859834',
                                  style: AppTextSize.captionStyle(context,
                                      color: Colors.black87),
                                ),
                                Text(
                                  '0086 13503032311',
                                  style: AppTextSize.captionStyle(context,
                                      color: Colors.black87),
                                ),
                                Text(
                                  '0086 (579)85568522',
                                  style: AppTextSize.captionStyle(context,
                                      color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EMail :',
                                  style: AppTextSize.captionStyle(context,
                                      color: Colors.black87)
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'bbd@bbdcompany.com',
                                  style: AppTextSize.captionStyle(context,
                                      color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Ligne verticale séparatrice
              Container(
                width: 2,
                color: primaryColor,
              ),

              // Section droite avec logo sur fond blanc
              Padding(
                padding: const EdgeInsets.all(12),
                child: Image.memory(
                  logoBytes!,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Titre de la facture (différent selon le type)
        Text(
          isVersement ? 'Payment Invoice' : 'Market Finance Invoice',
          style: AppTextSize.headlineStyle(context,
                  color: primaryColor, fontWeight: FontWeight.bold)
              .copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: 20),

        // Informations de la facture
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              _buildInfoRow(context, 'Invoice No.', invoiceNumber),
              _buildInfoRow(context, 'Invoice Date', dateFormat.format(invoiceDate)),
              _buildInfoRow(context, 'Currency', currency),
              _buildInfoRow(context, 'Exchange Rate', exchangeRate.toStringAsFixed(2)),
              if (isVersement) ...[
                if (montantVerser != null)
                  _buildInfoRow(
                      context,
                      'Amount Paid',
                      NumberFormat.currency(locale: 'fr_FR', symbol: currency)
                          .format(montantVerser)),
                if (montantRestant != null)
                  _buildInfoRow(
                      context,
                      'Remaining Amount',
                      NumberFormat.currency(locale: 'fr_FR', symbol: currency)
                          .format(montantRestant)),
              ],
              if (totalPurchaseOrder != null && !isVersement)
                _buildInfoRow(
                    context, 'Total Purchase Order', totalPurchaseOrder.toString()),
            ],
          ),
        ),

        // Section Client et Commissionnaire (uniquement pour les versements)
        if (isVersement) ...[
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Client
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client',
                      style: AppTextSize.titleStyle(context,
                          color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (customerName != null)
                      _buildClientInfoRow(context, 'Nom', customerName!),
                    if (customerPhone != null)
                      _buildClientInfoRow(context, 'Tél', customerPhone!),
                    if (customerRegisterNo != null)
                      _buildClientInfoRow(context, 'Register No.', customerRegisterNo!),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMISSIONNAIRE',
                      style: AppTextSize.titleStyle(context,
                          color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (commissionnaireName != null)
                      _buildClientInfoRow(context, 'Nom', commissionnaireName!),
                    if (commissionnairePhone != null)
                      _buildClientInfoRow(context, 'Tél', commissionnairePhone!),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              '$label:',
              style: AppTextSize.bodyStyle(context,
                  fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextSize.bodyStyle(context, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label :',
              style: AppTextSize.bodyStyle(context,
                  fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextSize.bodyStyle(context, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
