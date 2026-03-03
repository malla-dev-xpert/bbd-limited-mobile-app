import 'package:bbd_limited/core/constants/design_system.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../core/localization/app_localizations.dart';

class PersonalInfoCard extends StatelessWidget {
  final User user;

  const PersonalInfoCard({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      localizations.translate('personal_info_title'),
                      style: AppTextSize.headlineStyle(context, color: const Color(0xFF2D3748)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoRow(
                context,
                icon: Icons.person_outline,
                label: localizations.translate('last_name'),
                value: '${user.firstName ?? ''} ${user.lastName ?? ''}',
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                icon: Icons.email_outlined,
                label: localizations.translate('email'),
                value:
                    user.email ?? localizations.translate('no_data_available'),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                icon: Icons.phone_outlined,
                label: localizations.translate('phone'),
                value: user.phoneNumber ??
                    localizations.translate('no_data_available'),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                icon: Icons.work_outline,
                label: localizations.translate('role'),
                value: user.role!.name ??
                    localizations.translate('no_data_available'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(13, 26, 30, 73),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1A1E49),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextSize.bodyStyle(context, color: const Color(0xFF718096)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextSize.titleStyle(context, color: const Color(0xFF2D3748), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
