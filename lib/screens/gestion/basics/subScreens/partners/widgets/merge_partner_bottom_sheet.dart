import 'package:flutter/material.dart';
import 'package:bbd_limited/models/partner.dart';
import 'package:bbd_limited/core/services/partner_services.dart';
import 'package:bbd_limited/core/services/auth_services.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/utils/snackbar_utils.dart';
import 'package:intl/intl.dart';

class MergePartnerBottomSheet extends StatefulWidget {
  final Partner mainPartner;
  final Function() onMergeSuccess;

  const MergePartnerBottomSheet({
    Key? key,
    required this.mainPartner,
    required this.onMergeSuccess,
  }) : super(key: key);

  @override
  _MergePartnerBottomSheetState createState() =>
      _MergePartnerBottomSheetState();
}

class _MergePartnerBottomSheetState extends State<MergePartnerBottomSheet> {
  final TextEditingController searchController = TextEditingController();
  final PartnerServices _partnerServices = PartnerServices();
  final AuthService _authService = AuthService();

  List<Partner> _allPartners = [];
  List<Partner> _filteredPartners = [];
  Partner? _selectedPartner;
  bool _isLoading = false;
  bool _isMerging = false;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    setState(() => _isLoading = true);

    try {
      final partners = await _partnerServices.findCustomers();
      setState(() {
        _allPartners =
            partners.where((p) => p.id != widget.mainPartner.id).toList();
        _filteredPartners = _allPartners;
      });
    } catch (e) {
      showErrorTopSnackBar(
        context,
        AppLocalizations.of(context).translate('partner_loading_error'),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _searchPartners(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPartners = _allPartners;
      } else {
        _filteredPartners = _allPartners.where((partner) {
          final fullName =
              '${partner.firstName} ${partner.lastName}'.toLowerCase();
          final phone = partner.phoneNumber.toLowerCase();
          return fullName.contains(query.toLowerCase()) ||
              phone.contains(query.toLowerCase());
        }).toList();
      }
      _selectedPartner = null;
    });
  }

  Future<void> _mergePartners() async {
    if (_selectedPartner == null) return;

    setState(() => _isMerging = true);

    try {
      // Récupérer l'utilisateur connecté
      final currentUser = await _authService.getUserInfo();
      if (currentUser == null) {
        showErrorTopSnackBar(
          context,
          AppLocalizations.of(context).translate('user_not_authenticated'),
        );
        setState(() => _isMerging = false);
        return;
      }

      await _partnerServices.mergePartners(
        widget.mainPartner.id,
        _selectedPartner!.id,
        currentUser.id,
      );

      Navigator.pop(context);
      widget.onMergeSuccess();

      showSuccessTopSnackBar(
        context,
        AppLocalizations.of(context)
            .translate('partner_merge_success')
            .replaceAll('{duplicateName}',
                '${_selectedPartner!.firstName} ${_selectedPartner!.lastName}')
            .replaceAll('{mainName}',
                '${widget.mainPartner.firstName} ${widget.mainPartner.lastName}'),
      );
    } catch (e) {
      String errorMessage;
      switch (e.toString()) {
        case 'Exception: SAME_PARTNER_ERROR':
          errorMessage =
              AppLocalizations.of(context).translate('same_partner_error');
          break;
        case 'Exception: PARTNER_NOT_FOUND':
          errorMessage =
              AppLocalizations.of(context).translate('partner_not_found');
          break;
        case 'Exception: MERGE_ERROR':
          errorMessage =
              AppLocalizations.of(context).translate('partner_merge_error');
          break;
        case 'Exception: network_error':
          errorMessage =
              AppLocalizations.of(context).translate('network_error');
          break;
        default:
          errorMessage =
              AppLocalizations.of(context).translate('partner_merge_error');
      }

      showErrorTopSnackBar(context, errorMessage);
    } finally {
      setState(() => _isMerging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'CNY',
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header - Scrollable
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.merge_type,
                              color: Color(0xFF1A1E49),
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                localizations.translate('merge_partners'),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1E49),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close,
                                  color: Colors.grey, size: 24),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Main partner info
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1E49).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1A1E49).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1E49),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localizations.translate('main_partner'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${widget.mainPartner.firstName} ${widget.mainPartner.lastName}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1E49),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (widget
                                        .mainPartner.phoneNumber.isNotEmpty)
                                      Text(
                                        widget.mainPartner.phoneNumber,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search field - Scrollable
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: buildTextField(
                      controller: searchController,
                      label: localizations.translate('search_partner_to_merge'),
                      icon: Icons.search,
                      onChanged: _searchPartners,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Partners list - Scrollable
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        )
                      : _filteredPartners.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(
                                localizations.translate('no_partner_found'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _filteredPartners.length,
                              itemBuilder: (context, index) {
                                final partner = _filteredPartners[index];
                                final isSelected =
                                    _selectedPartner?.id == partner.id;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () {
                                      setState(
                                          () => _selectedPartner = partner);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF1A1E49)
                                                .withOpacity(0.1)
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.green
                                              : Colors.grey[200]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.green
                                                  : Colors.grey[400],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${partner.firstName} ${partner.lastName}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFF1A1E49)
                                                        : Colors.black87,
                                                  ),
                                                ),
                                                if (partner
                                                    .phoneNumber.isNotEmpty)
                                                  const SizedBox(height: 6),
                                                if (partner
                                                    .phoneNumber.isNotEmpty)
                                                  Text(
                                                    partner.phoneNumber,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        localizations.translate(
                                                            'balance'),
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.blue,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      currencyFormat.format(
                                                          partner.balance ?? 0),
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            (partner.balance ??
                                                                        0) >=
                                                                    0
                                                                ? Colors
                                                                    .green[600]
                                                                : Colors
                                                                    .red[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                  // Add some bottom padding for better scrolling
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Merge button - Fixed at bottom
          if (_selectedPartner != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Comparison summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.translate('merge_summary'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1E49),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPartnerSummary(
                                widget.mainPartner,
                                localizations.translate('main_partner'),
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildPartnerSummary(
                                _selectedPartner!,
                                localizations.translate('duplicate_partner'),
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Merge button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isMerging ? null : _mergePartners,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isMerging
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.merge_type,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  localizations.translate('merge_now'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartnerSummary(Partner partner, String label, Color color) {
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'CNY',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${partner.firstName} ${partner.lastName}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            partner.phoneNumber,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(partner.balance ?? 0),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: (partner.balance ?? 0) >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
