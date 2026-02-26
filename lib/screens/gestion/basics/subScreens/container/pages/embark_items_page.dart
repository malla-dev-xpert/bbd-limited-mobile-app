import 'package:flutter/material.dart';
import 'package:bbd_limited/components/reusable_item_card.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/services/item_services.dart';
import 'package:bbd_limited/models/achats/achat.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';

/// Full-page screen to select and embark items into a container.
/// Reuses the same UI design as the item selection step during container creation.
class EmbarkItemsPage extends StatefulWidget {
  final int containerId;

  const EmbarkItemsPage({
    super.key,
    required this.containerId,
  });

  @override
  State<EmbarkItemsPage> createState() => _EmbarkItemsPageState();
}

class _EmbarkItemsPageState extends State<EmbarkItemsPage> {
  final ContainerServices _containerServices = ContainerServices();
  final ItemServices _itemServices = ItemServices();
  final AuthService _authService = AuthService();

  List<Items> _availableItems = [];
  final Set<int> _selectedItemIds = {};
  bool _isLoadingItems = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableItems();
  }

  Future<void> _loadAvailableItems() async {
    setState(() => _isLoadingItems = true);
    try {
      final list = await _itemServices.findAllNotInContainer();
      setState(() {
        _availableItems = list;
        _isLoadingItems = false;
      });
    } catch (_) {
      setState(() => _isLoadingItems = false);
    }
  }

  Future<void> _embarkItems() async {
    if (_selectedItemIds.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final user = await _authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('user_not_connected'),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final itemIds = _selectedItemIds.toList();
      final result = await _containerServices.addItemsToContainer(
        widget.containerId,
        itemIds,
        userId: user.id.toInt(),
      );

      if (result.isSuccess) {
        showSuccessTopSnackBar(
          context,
          AppLocalizations.of(context)
              .translate('container_items_embarked_success'),
        );
        if (mounted) Navigator.of(context).pop(true);
      } else {
        showErrorTopSnackBar(
          context,
          result.errorMessage ??
              AppLocalizations.of(context).translate('container_embark_error'),
        );
      }
    } catch (e) {
      showErrorTopSnackBar(
        context,
        '${AppLocalizations.of(context).translate('error')}: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStepCard({required Widget child}) {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildItemSelectionCard({
    required Items item,
    required AppLocalizations loc,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ReusableItemCard(
      item: item,
      onTap: onTap,
      showPurchaseInfo: true,
      extraDetails: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (_) => onTap(),
            activeColor: const Color(0xFF1A1E49),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isSelected
                ? loc.translate('container_item_selected')
                : loc.translate('container_item_select'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? const Color(0xFF1A1E49) : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          loc.translate('container_embark_items'),
          style: const TextStyle(
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    loc.translate('container_items_step_title'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1E49),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.translate('container_items_step_subtitle'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingItems)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_availableItems.isEmpty)
                    _buildStepCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                loc.translate('container_no_items_available'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._availableItems.map(
                      (item) => _buildItemSelectionCard(
                        item: item,
                        loc: loc,
                        isSelected: item.id != null &&
                            _selectedItemIds.contains(item.id),
                        onTap: () {
                          setState(() {
                            if (item.id == null) return;
                            if (_selectedItemIds.contains(item.id)) {
                              _selectedItemIds.remove(item.id);
                            } else {
                              _selectedItemIds.add(item.id!);
                            }
                          });
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_selectedItemIds.isEmpty || _isSubmitting)
                      ? null
                      : _embarkItems,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF1A1E49),
                    disabledBackgroundColor: Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_circle_outline,
                          color: Colors.white),
                  label: Text(
                    _isSubmitting
                        ? loc.translate('container_form_saving')
                        : loc.translate('container_embark_items_button'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
