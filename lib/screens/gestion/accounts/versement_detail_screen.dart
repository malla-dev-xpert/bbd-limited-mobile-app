import 'package:flutter/material.dart';
import 'package:bbd_limited/models/versement.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/screens/gestion/accounts/widgets/purchase_dialog.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/majesticons.dart';
import 'package:intl/intl.dart';

class VersementDetailScreen extends StatefulWidget {
  final Versement versement;
  final VoidCallback? onVersementUpdated;

  const VersementDetailScreen({
    Key? key,
    required this.versement,
    this.onVersementUpdated,
  }) : super(key: key);

  @override
  State<VersementDetailScreen> createState() => _VersementDetailScreenState();
}

class _VersementDetailScreenState extends State<VersementDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool isLoading = false;
  bool _isInfoExpanded = true;
  bool _isArticlesExpanded = false;
  late NumberFormat currencyFormat;

  @override
  void initState() {
    super.initState();
    currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: widget.versement.deviseCode ?? 'USD',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildDetailRow(String label, String? value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontSize: 15,
            ),
          ),
          Flexible(
            child: Text(
              value ?? '',
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF1A1E49),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1A1E49),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildArticleList() {
    final allLignes =
        widget.versement.achats?.expand((a) => a.items ?? []).toList() ?? [];
    final filteredLignes = _searchQuery.isEmpty
        ? allLignes
        : allLignes.where((ligne) {
            final description = (ligne.description ?? '').toLowerCase();
            final itemId = ligne.id?.toString().toLowerCase() ?? '';
            final searchLower = _searchQuery.toLowerCase();
            return description.contains(searchLower) ||
                itemId.contains(searchLower);
          }).toList();

    if (allLignes.isEmpty) {
      return const Center(
        child: Text("Pas d'articles achetés pour ce versement."),
      );
    }

    if (filteredLignes.isEmpty) {
      return const Center(
        child: Text("Aucun article trouvé pour cette recherche."),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredLignes.length,
      itemBuilder: (context, index) {
        final ligne = filteredLignes[index];
        Achat? achat;
        for (var a in widget.versement.achats ?? []) {
          if (a.items?.contains(ligne) ?? false) {
            achat = a;
            break;
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ligne.description ?? 'Article sans nom',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (achat?.fournisseur != null) ...[
                  const SizedBox(height: 4),
                  _buildDetailItem(
                    'Fournisseur',
                    '${achat!.fournisseur} | ${achat.fournisseurPhone}',
                  ),
                ],
                const SizedBox(height: 4),
                _buildDetailItem('Quantité', '${ligne.quantity}'),
                const SizedBox(height: 4),
                _buildDetailItem(
                  'Prix Unitaire',
                  currencyFormat.format(ligne.unitPrice ?? 0),
                ),
                const SizedBox(height: 4),
                _buildDetailItem(
                  'Total',
                  currencyFormat.format(
                    ligne.totalPrice ??
                        (ligne.quantity ?? 0) * (ligne.unitPrice ?? 0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handlePurchase() {
    if (widget.versement.partnerId == null || widget.versement.id == null) {
      showErrorTopSnackBar(
        context,
        "Informations du versement incomplètes",
      );
      return;
    }

    PurchaseDialog.show(
      context,
      (achat) {
        widget.onVersementUpdated?.call();
      },
      widget.versement.partnerId!,
      widget.versement.id!,
      widget.versement.achats?.isNotEmpty == true
          ? widget.versement.achats!.first.invoiceNumber ?? ''
          : '',
    );
  }

  Widget _buildNoteField(String? note) {
    if (note == null || note.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Note",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              note,
              style: const TextStyle(
                color: Color(0xFF1A1E49),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleInfo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isInfoExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isInfoExpanded = expanded;
            });
          },
          title: const Text(
            "Informations du versement",
            style: TextStyle(
              color: Color(0xFF1A1E49),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow("Référence", widget.versement.reference),
                  _buildDetailRow("Type", widget.versement.type),
                  _buildNoteField(widget.versement.note),
                  _buildDetailRow("Client", widget.versement.partnerName),
                  _buildDetailRow(
                      "Téléphone", "${widget.versement.partnerPhone}"),
                  _buildDetailRow(
                    "Commissionnaire",
                    widget.versement.commissionnaireName ?? 'N/V',
                  ),
                  _buildDetailRow(
                    "Téléphone",
                    "${widget.versement.commissionnairePhone}",
                  ),
                  _buildDetailRow(
                    "Montant versé",
                    currencyFormat.format(widget.versement.montantVerser),
                  ),
                  _buildDetailRow(
                    "Montant restante",
                    currencyFormat.format(widget.versement.montantRestant),
                  ),
                  _buildDetailRow(
                    "Date de versement",
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(widget.versement.createdAt!),
                  ),
                  _buildDetailRow(
                    "Total des achats",
                    widget.versement.achats!
                        .expand((a) => a.items ?? [])
                        .length
                        .toString(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleArticles() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isArticlesExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isArticlesExpanded = expanded;
            });
          },
          title: const Text(
            "La liste des articles achetés",
            style: TextStyle(
              color: Color(0xFF1A1E49),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un article...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF1A1E49),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: _buildArticleList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A1E49),
        title: const Text(
          "Détails du versement",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handlePurchase,
        backgroundColor: const Color(0xFF1A1E49),
        icon: const Iconify(
          Majesticons.money_hand_line,
          color: Colors.white,
        ),
        label: const Text(
          'Effectuer un achat',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCollapsibleInfo(),
                    const SizedBox(height: 16),
                    _buildCollapsibleArticles(),
                    const SizedBox(height: 80), // Space for FAB
                  ],
                ),
              ),
            ),
    );
  }
}
