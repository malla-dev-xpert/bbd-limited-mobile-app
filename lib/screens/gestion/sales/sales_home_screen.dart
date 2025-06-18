import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:flutter/material.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/enums/status.dart';

class SalesHomeScreen extends StatelessWidget {
  const SalesHomeScreen({super.key});

  void _showHistoriqueBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const HistoriqueAchatsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Gestion des achats',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF1A1E49),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec statistiques
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A1E49),
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              context,
                              'Ventes du jour',
                              '0',
                              Icons.today,
                              Colors.white,
                            ),
                            _buildStatItem(
                              context,
                              'Ventes du mois',
                              '0',
                              Icons.calendar_month,
                              Colors.white,
                            ),
                            _buildStatItem(
                              context,
                              'Chiffre d\'affaires',
                              '0',
                              Icons.currency_yen,
                              Colors.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Section des actions rapides
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Actions rapides',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildActionCard(
                      context,
                      'Nouveau achat',
                      Icons.add_shopping_cart,
                      () {},
                      Colors.blue,
                    ),
                    _buildActionCard(
                      context,
                      'Historique',
                      Icons.history,
                      () => _showHistoriqueBottomSheet(context),
                      Colors.orange,
                    ),
                    _buildActionCard(
                      context,
                      'Clients',
                      Icons.people,
                      () {},
                      Colors.green,
                    ),
                    _buildActionCard(
                      context,
                      'Rapports',
                      Icons.bar_chart,
                      () {},
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 32,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: color.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoriqueAchatsSheet extends StatefulWidget {
  const HistoriqueAchatsSheet({super.key});

  @override
  State<HistoriqueAchatsSheet> createState() => _HistoriqueAchatsSheetState();
}

class _HistoriqueAchatsSheetState extends State<HistoriqueAchatsSheet> {
  final AchatServices _achatsService = AchatServices();
  List<Achat> _achats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerAchats();
  }

  Future<void> _chargerAchats() async {
    final achats = await _achatsService.findAll();
    setState(() {
      _achats = achats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historique des achats',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_achats.isEmpty)
            const Center(
              child: Text('Aucun achat trouvé'),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _achats.length,
                itemBuilder: (context, index) {
                  final achat = _achats[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        'Réf: ${achat.referenceVersement ?? "N/A"}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Client: ${achat.client ?? "N/A"}'),
                          if (achat.clientPhone != null)
                            Text('Tél: ${achat.clientPhone}'),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${achat.montantVerser?.toStringAsFixed(2) ?? "0"} €',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(achat.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              achat.status?.name ?? "N/A",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _showAchatDetails(context, achat),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(Status? status) {
    switch (status) {
      case Status.PENDING:
        return Colors.blue;
      case Status.RECEIVED:
        return Colors.green;
      case Status.DELETE:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showAchatDetails(BuildContext context, Achat achat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AchatDetailsSheet(achat: achat),
    );
  }
}

class AchatDetailsSheet extends StatelessWidget {
  final Achat achat;

  const AchatDetailsSheet({super.key, required this.achat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Détails de l\'achat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Référence: ${achat.referenceVersement ?? "N/A"}'),
          Text('Client: ${achat.client ?? "N/A"}'),
          if (achat.clientPhone != null)
            Text('Téléphone: ${achat.clientPhone}'),
          Text(
              'Montant versé: ${achat.montantVerser?.toStringAsFixed(2) ?? "0"} €'),
          if (achat.montantRestant != null)
            Text(
                'Montant restant: ${achat.montantRestant?.toStringAsFixed(2)} €'),
          const SizedBox(height: 16),
          const Text(
            'Articles achetés:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (achat.items != null && achat.items!.isNotEmpty)
            ...achat.items!.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.description ?? "N/A",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Quantité: ${item.quantity ?? 0}'),
                              Text(
                                  'Prix unitaire: ${item.unitPrice?.toStringAsFixed(2) ?? "0"} €'),
                            ],
                          ),
                          if (item.totalPrice != null)
                            Text(
                              'Total: ${item.totalPrice?.toStringAsFixed(2)} €',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          if (item.supplierName != null)
                            Text('Fournisseur: ${item.supplierName}'),
                        ],
                      ),
                    ),
                  ),
                ))
          else
            const Text('Aucun article trouvé'),
        ],
      ),
    );
  }
}
