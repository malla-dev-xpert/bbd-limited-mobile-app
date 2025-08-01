import 'package:flutter/material.dart';
import '../models/user.dart';

class PersonalInfoCard extends StatelessWidget {
  final User user;

  const PersonalInfoCard({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Informations Personnelles',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
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
              icon: Icons.person_outline,
              label: 'Nom',
              value: '${user.firstName ?? ''} ${user.lastName ?? ''}',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email ?? 'Non renseigné',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: 'Téléphone',
              value: user.phoneNumber ?? 'Non renseigné',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.work_outline,
              label: 'Rôle',
              value: user.role!.name ?? 'Non renseigné',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
