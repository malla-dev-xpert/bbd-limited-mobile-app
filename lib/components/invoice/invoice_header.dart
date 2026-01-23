import 'dart:typed_data';
import 'package:flutter/material.dart';
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
                      const Text(
                        'BBD LIMITED',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: 1.5,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Adresse en rouge
                      const Text(
                        '1Floor, Building 10,Room 102, Zhao Zhai san qu, Yiwu, Zhejiang, China',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        '中国 浙江省义乌市赵宅3区10栋1单元102',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // Ligne séparatrice bleu foncé
                      const SizedBox(height: 12),
                      Container(
                        height: 2,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 12),

                      // Informations de contact
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Téléphones à gauche
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contact :',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '0086 18678859834',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '0086 13503032311',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '0086 (579)85568522',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Email à droite
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EMail :',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'bbd@bbdcompany.com',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                  ),
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
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: primaryColor,
            letterSpacing: 1.2,
          ),
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
              _buildInfoRow('Invoice No.', invoiceNumber),
              _buildInfoRow('Invoice Date', dateFormat.format(invoiceDate)),
              _buildInfoRow('Currency', currency),
              _buildInfoRow('Exchange Rate', exchangeRate.toStringAsFixed(2)),
              if (isVersement) ...[
                if (montantVerser != null)
                  _buildInfoRow(
                      'Amount Paid',
                      NumberFormat.currency(locale: 'fr_FR', symbol: currency)
                          .format(montantVerser)),
                if (montantRestant != null)
                  _buildInfoRow(
                      'Remaining Amount',
                      NumberFormat.currency(locale: 'fr_FR', symbol: currency)
                          .format(montantRestant)),
              ],
              if (totalPurchaseOrder != null && !isVersement)
                _buildInfoRow(
                    'Total Purchase Order', totalPurchaseOrder.toString()),
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
                    const Text(
                      'Client',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (customerName != null)
                      _buildClientInfoRow('Nom', customerName!),
                    if (customerPhone != null)
                      _buildClientInfoRow('Tél', customerPhone!),
                    if (customerRegisterNo != null)
                      _buildClientInfoRow('Register No.', customerRegisterNo!),
                  ],
                ),
              ),

              // Section Commissionnaire
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMISSIONNAIRE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (commissionnaireName != null)
                      _buildClientInfoRow('Nom', commissionnaireName!),
                    if (commissionnairePhone != null)
                      _buildClientInfoRow('Tél', commissionnairePhone!),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
