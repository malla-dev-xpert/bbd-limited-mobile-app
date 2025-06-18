import 'package:flutter/material.dart';
import 'package:bbd_limited/core/services/achat_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'achat_details_sheet.dart';

class HistoriqueAchatsScreen extends StatefulWidget {
  const HistoriqueAchatsScreen({super.key});

  @override
  State<HistoriqueAchatsScreen> createState() => _HistoriqueAchatsScreenState();
}

class _HistoriqueAchatsScreenState extends State<HistoriqueAchatsScreen> {
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Historique des achats',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _achats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun achat trouvé',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _chargerAchats,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _achats.length,
                    itemBuilder: (context, index) {
                      final achat = _achats[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showAchatDetails(context, achat),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Réf. V: ${achat.referenceVersement ?? "N/A"}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(achat.status)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          achat.status?.name ?? "N/A",
                                          style: TextStyle(
                                            color:
                                                _getStatusColor(achat.status),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 16,
                                        color: Colors.grey[700]!,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          achat.client ?? "N/A",
                                          style: TextStyle(
                                            color: Colors.grey[700]!,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (achat.clientPhone != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_outlined,
                                          size: 16,
                                          color: Colors.grey[700]!,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          achat.clientPhone!,
                                          style: TextStyle(
                                            color: Colors.grey[700]!,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Montant total',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${achat.montantTotal?.toStringAsFixed(2) ?? "0"} ¥',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1E49),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Color _getStatusColor(Status? status) {
    switch (status) {
      case Status.PENDING:
        return Colors.amber;
      case Status.COMPLETED:
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
      backgroundColor: Colors.transparent,
      builder: (context) => AchatDetailsSheet(achat: achat),
    );
  }
}
