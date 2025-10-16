import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';

class PrivacyPolicyBottomSheet extends StatelessWidget {
  const PrivacyPolicyBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  localizations.translate('privacy_policy_title'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Introduction
                  _buildSection(
                    context,
                    localizations.translate('privacy_introduction_title'),
                    localizations.translate('privacy_introduction_content'),
                    Icons.info_outline,
                    Colors.blue,
                  ),

                  const SizedBox(height: 24),

                  // Collecte des données
                  _buildSection(
                    context,
                    localizations.translate('privacy_collection_title'),
                    localizations.translate('privacy_collection_content'),
                    Icons.collections,
                    Colors.green,
                  ),

                  const SizedBox(height: 24),

                  // Types de données collectées
                  _buildSection(
                    context,
                    localizations.translate('privacy_data_types_title'),
                    localizations.translate('privacy_data_types_content'),
                    Icons.data_usage,
                    Colors.orange,
                  ),

                  const SizedBox(height: 24),

                  // Utilisation des données
                  _buildSection(
                    context,
                    localizations.translate('privacy_usage_title'),
                    localizations.translate('privacy_usage_content'),
                    Icons.analytics,
                    Colors.purple,
                  ),

                  const SizedBox(height: 24),

                  // Partage des données
                  _buildSection(
                    context,
                    localizations.translate('privacy_sharing_title'),
                    localizations.translate('privacy_sharing_content'),
                    Icons.share,
                    Colors.teal,
                  ),

                  const SizedBox(height: 24),

                  // Protection des données
                  _buildSection(
                    context,
                    localizations.translate('privacy_protection_title'),
                    localizations.translate('privacy_protection_content'),
                    Icons.security,
                    Colors.red,
                  ),

                  const SizedBox(height: 24),

                  // Droits des utilisateurs
                  _buildSection(
                    context,
                    localizations.translate('privacy_rights_title'),
                    localizations.translate('privacy_rights_content'),
                    Icons.verified_user,
                    Colors.indigo,
                  ),

                  const SizedBox(height: 24),

                  // Conservation des données
                  _buildSection(
                    context,
                    localizations.translate('privacy_retention_title'),
                    localizations.translate('privacy_retention_content'),
                    Icons.schedule,
                    Colors.amber,
                  ),

                  const SizedBox(height: 24),

                  // Contact
                  _buildSection(
                    context,
                    localizations.translate('privacy_contact_title'),
                    localizations.translate('privacy_contact_content'),
                    Icons.contact_support,
                    Colors.grey,
                  ),

                  const SizedBox(height: 32),

                  // Date de mise à jour
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
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Padding bottom pour éviter que le contenu soit coupé
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
