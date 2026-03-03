import 'package:flutter/material.dart';
import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:bbd_limited/core/localization/app_localizations.dart';

/// Page plein écran pour la politique de confidentialité.
/// Remplace l'ancien bottom sheet.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          localizations.translate('privacy_policy_title'),
          style: AppTextSize.titleStyle(context, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1E49),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              localizations.translate('privacy_introduction_title'),
              localizations.translate('privacy_introduction_content'),
              Icons.info_outline,
              Colors.blue,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              localizations.translate('privacy_collection_title'),
              localizations.translate('privacy_collection_content'),
              Icons.collections,
              Colors.green,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              localizations.translate('privacy_data_types_title'),
              localizations.translate('privacy_data_types_content'),
              Icons.data_usage,
              Colors.orange,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              localizations.translate('privacy_usage_title'),
              localizations.translate('privacy_usage_content'),
              Icons.analytics,
              Colors.purple,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              localizations.translate('privacy_sharing_title'),
              localizations.translate('privacy_sharing_content'),
              Icons.share,
              Colors.teal,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              localizations.translate('privacy_protection_title'),
              localizations.translate('privacy_protection_content'),
              Icons.security,
              Colors.red,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              localizations.translate('privacy_rights_title'),
              localizations.translate('privacy_rights_content'),
              Icons.verified_user,
              Colors.indigo,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              localizations.translate('privacy_retention_title'),
              localizations.translate('privacy_retention_content'),
              Icons.schedule,
              Colors.amber,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              localizations.translate('privacy_contact_title'),
              localizations.translate('privacy_contact_content'),
              Icons.contact_support,
              Colors.grey,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.update,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizations.translate('privacy_last_updated'),
                      style: AppTextSize.bodyStyle(context,
                              color: Colors.grey[600])
                          .copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextSize.titleStyle(context,
                      fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: AppTextSize.bodyStyle(context).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
