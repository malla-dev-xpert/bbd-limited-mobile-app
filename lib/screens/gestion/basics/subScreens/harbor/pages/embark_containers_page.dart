import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/services/container_services.dart';
import 'package:bbd_limited/core/enums/status.dart';
import 'package:bbd_limited/models/container.dart';
import 'package:bbd_limited/models/embarquement.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

class EmbarkContainersPage extends StatefulWidget {
  final int harborId;
  final String? harborName;

  const EmbarkContainersPage({
    super.key,
    required this.harborId,
    this.harborName,
  });

  @override
  State<EmbarkContainersPage> createState() => _EmbarkContainersPageState();
}

class _EmbarkContainersPageState extends State<EmbarkContainersPage> {
  final ContainerServices _containerServices = ContainerServices();
  final AuthService _authService = AuthService();
  List<Containers> _availableContainers = [];
  final Set<int> _selectedIds = {};
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadContainers();
  }

  Future<void> _loadContainers() async {
    setState(() => _isLoading = true);
    try {
      final list =
          await _containerServices.findAllContainerNotInHarbor(page: 0);
      if (mounted) {
        setState(() {
          _availableContainers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)!
              .translate('harbor_embark_error_loading'),
        );
      }
    }
  }

  void _toggleSelection(Containers c) {
    if (c.id == null) return;
    setState(() {
      if (_selectedIds.contains(c.id)) {
        _selectedIds.remove(c.id);
      } else {
        _selectedIds.add(c.id!);
      }
    });
  }

  Future<void> _submitEmbark() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final user = await _authService.getUserInfo();
      if (user == null) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)!.translate('user_not_connected'),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final request = HarborEmbarquementRequest(
        harborId: widget.harborId,
        containerId: _selectedIds.toList(),
      );
      final result = await _containerServices.embarquerContainerToHarbor(
        request,
        user.id.toInt(),
      );

      if (result == "SUCCESS" && mounted) {
        showSuccessTopSnackBar(
          context,
          AppLocalizations.of(context)!.translate('harbor_embark_success'),
        );
        Navigator.of(context).pop(_selectedIds.length);
      } else if (mounted) {
        String message;
        switch (result) {
          case "CONTAINER_ALREADY_IN_ANOTHER_HARBOR":
            message = AppLocalizations.of(context)!
                .translate('harbor_embark_error_already_in_harbor');
            break;
          case "HARBOR_NOT_AVAILABLE":
            message = AppLocalizations.of(context)!
                .translate('harbor_embark_error_harbor_not_available');
            break;
          default:
            message = AppLocalizations.of(context)!
                .translate('harbor_embark_error_generic');
        }
        showErrorTopSnackBar(context, message);
      }
    } catch (e) {
      if (mounted) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context)!
              .translate('harbor_embark_error_generic'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          loc.translate('harbor_embark_title'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: widget.harborName != null && widget.harborName!.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 12),
                    child: Text(
                      widget.harborName!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableContainers.isEmpty
              ? _buildEmptyState(loc)
              : RefreshIndicator(
                  onRefresh: _loadContainers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _availableContainers.length,
                    itemBuilder: (context, index) {
                      final c = _availableContainers[index];
                      return _buildContainerCard(c, loc);
                    },
                  ),
                ),
      bottomNavigationBar: _availableContainers.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || _selectedIds.isEmpty)
                        ? null
                        : _submitEmbark,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            '${loc.translate('harbor_embark_button')} (${_selectedIds.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              loc.translate('harbor_embark_empty_title'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              loc.translate('harbor_embark_empty_subtitle'),
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContainerCard(Containers c, AppLocalizations loc) {
    final isSelected = c.id != null && _selectedIds.contains(c.id);
    final itemsCount = c.items
            ?.where((i) =>
                i.status != Status.DELETE &&
                i.status != Status.DELETE_ON_CONTAINER)
            .length ??
        c.packages?.length ??
        0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.06),
        child: InkWell(
          onTap: () => _toggleSelection(c),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(c),
                  activeColor: const Color(0xFF1A1E49),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.reference ?? '—',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1E49),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '$itemsCount ${loc.translate('harbor_embark_items_count')}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.straighten,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${c.size ?? '—'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (c.departureHarborName != null ||
                          c.arrivalHarborName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.sailing,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${c.departureHarborName ?? '—'} → ${c.arrivalHarborName ?? '—'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color:
                      isSelected ? const Color(0xFF1A1E49) : Colors.grey[400],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
