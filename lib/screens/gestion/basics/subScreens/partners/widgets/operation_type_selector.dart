import 'package:bbd_limited/screens/gestion/basics/subScreens/partners/partner_detail_screen.dart';
import 'package:flutter/material.dart';

class OperationTypeSelector extends StatelessWidget {
  final OperationType selectedOperationType;
  final Function(OperationType) onTypeSelected;

  const OperationTypeSelector({
    Key? key,
    required this.selectedOperationType,
    required this.onTypeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: _buildOperationTypeButton(OperationType.versements,
                'Versements', Icons.payments_outlined),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _buildOperationTypeButton(
                OperationType.expeditions, 'Colis', Icons.inventory_2),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _buildOperationTypeButton(
                OperationType.debts, 'Dettes', Icons.money_off_csred),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationTypeButton(
      OperationType type, String label, IconData icon) {
    final isSelected = selectedOperationType == type;
    return InkWell(
      onTap: () => onTypeSelected(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        constraints: const BoxConstraints(minWidth: 0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7F78AF) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
