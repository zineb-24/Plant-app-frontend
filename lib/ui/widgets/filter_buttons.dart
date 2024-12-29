import 'package:flutter/material.dart';

class FilterButtons extends StatefulWidget {
  final Function(String filter) onFilterChanged;

  const FilterButtons({super.key, required this.onFilterChanged});

  @override
  State<FilterButtons> createState() => _FilterButtonsState();
}

class _FilterButtonsState extends State<FilterButtons> {
  String selectedFilter = 'plants'; // Default filter

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // All button (disabled)
        FilterButton(
          label: 'All',
          icon: Icons.category,
          isSelected: selectedFilter == 'all',
          isEnabled: false, // Disabled button
          onTap: () {
            // Do nothing since it's disabled
          },
        ),
        const SizedBox(width: 8),

        // Plants button (enabled)
        FilterButton(
          label: 'Plants',
          icon: Icons.eco,
          isSelected: selectedFilter == 'plants',
          isEnabled: true,
          onTap: () {
            setState(() {
              selectedFilter = 'plants';
            });
            widget.onFilterChanged('plants');
          },
        ),
        const SizedBox(width: 8),

        // Pets button (disabled)
        FilterButton(
          label: 'Pets',
          icon: Icons.pets,
          isSelected: selectedFilter == 'pets',
          isEnabled: false, // Disabled button
          onTap: () {
            // Do nothing since it's disabled
          },
        ),
      ],
    );
  }
}

class FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const FilterButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3C3C3C) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
