import 'package:flutter/material.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/screens/gestion/sales/achat_details_sheet.dart';
import 'package:bbd_limited/screens/gestion/sales/edit_article_screen.dart';

/// Écran complet (page) affichant le détail d'un achat.
/// Remplace le bottom sheet [AchatDetailsSheet] pour une navigation en page.
class AchatDetailScreen extends StatefulWidget {
  final Achat achat;
  final VoidCallback? onItemConfirmed;
  final VoidCallback? onItemReversed;

  const AchatDetailScreen({
    super.key,
    required this.achat,
    this.onItemConfirmed,
    this.onItemReversed,
  });

  @override
  State<AchatDetailScreen> createState() => _AchatDetailScreenState();
}

class _AchatDetailScreenState extends State<AchatDetailScreen> {
  late Achat _achat;

  @override
  void initState() {
    super.initState();
    _achat = widget.achat;
  }

  Future<void> _openEditArticle(Items item) async {
    final updated = await Navigator.push<Items>(
      context,
      MaterialPageRoute<Items>(
        builder: (context) => EditArticleScreen(
          item: item,
          achat: _achat,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        final idx = _achat.items?.indexWhere((i) => i.id == updated.id) ?? -1;
        if (idx != -1 && _achat.items != null) {
          final newItems = List<Items>.from(_achat.items!);
          newItems[idx] = updated;
          _achat = _achat.copyWith(items: newItems);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)
              .translate('purchase_history_details_title'),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AchatDetailsSheet(
        achat: _achat,
        fullScreen: true,
        onItemConfirmed: widget.onItemConfirmed,
        onItemReversed: widget.onItemReversed,
        onEditArticle: _openEditArticle,
      ),
    );
  }
}
