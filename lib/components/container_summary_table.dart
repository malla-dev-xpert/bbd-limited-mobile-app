import 'package:bbd_limited/models/container_client_summary.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:flutter/material.dart';

/// Widget de tableau affichant le résumé agrégé par client des items d'un conteneur.
///
/// Ce widget reproduit le format de facture avec les colonnes:
/// N | MARK | CTNS | T.CBM | CFA | TELEPHONE | KGS
///
/// Le tableau est scrollable horizontalement pour gérer l'overflow sur petits écrans.
class ContainerSummaryTable extends StatelessWidget {
  /// Liste des résumés par client à afficher dans le tableau
  final List<ContainerClientSummary> summaries;

  const ContainerSummaryTable({
    Key? key,
    required this.summaries,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Cas où il n'y a pas de données
    if (summaries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Aucune donnée disponible',
            style: AppTextSize.bodyStyle(context, color: Colors.grey[600]),
          ),
        ),
      );
    }

    // Tableau avec scroll horizontal pour gérer l'overflow
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        // En-tête avec couleur de fond
        headingRowColor: MaterialStateProperty.all(
          const Color(0xFF1A1E49).withOpacity(0.1),
        ),
        // Bordures du tableau
        border: TableBorder.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        // Hauteur de ligne en-tête
        headingRowHeight: 48,
        // Hauteur de ligne de données
        dataRowHeight: 56,
        // Colonnes du tableau
        columns: [
          DataColumn(
            label: Text(
              'N',
              style: AppTextSize.subtitleStyle(context, fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'MARK',
              style: AppTextSize.subtitleStyle(context, fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'CTNS',
              style: AppTextSize.subtitleStyle(context, fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'T.CBM',
              style: AppTextSize.subtitleStyle(context, fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
          DataColumn(
            label: Text(
              'CFA',
              style: AppTextSize.subtitleStyle(context, fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'TELEPHONE',
              style: AppTextSize.subtitleStyle(context, fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'KGS',
              style: AppTextSize.subtitleStyle(context, fontWeight: FontWeight.bold),
            ),
            numeric: true,
          ),
        ],
        // Lignes de données
        rows: summaries.asMap().entries.map((entry) {
          final index = entry.key;
          final summary = entry.value;

          return DataRow(
            cells: [
              // Numéro de ligne (commence à 1)
              DataCell(
                Text(
                  '${index + 1}',
                  style: AppTextSize.bodyStyle(context),
                ),
              ),
              // Nom du client (MARK)
              DataCell(
                Text(
                  summary.clientName,
                  style: AppTextSize.bodyStyle(context, fontWeight: FontWeight.w500),
                ),
              ),
              // Nombre total de cartons (CTNS) - entier
              DataCell(
                Text(
                  '${summary.totalCartons}',
                  style: AppTextSize.bodyStyle(context),
                ),
              ),
              // Volume total CBM (T.CBM) - 3 décimales
              DataCell(
                Text(
                  summary.totalCbm.toStringAsFixed(3),
                  style: AppTextSize.bodyStyle(context),
                ),
              ),
              // CFA - temporairement statique
              DataCell(
                Text(
                  '-',
                  style: AppTextSize.bodyStyle(context, color: Colors.grey[600]),
                ),
              ),
              // TELEPHONE - temporairement statique
              DataCell(
                Text(
                  '-',
                  style: AppTextSize.bodyStyle(context, color: Colors.grey[600]),
                ),
              ),
              // Poids total (KGS) - arrondi à l'entier
              DataCell(
                Text(
                  '${summary.totalWeight.round()}',
                  style: AppTextSize.bodyStyle(context),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
