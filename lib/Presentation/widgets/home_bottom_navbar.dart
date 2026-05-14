import 'package:flutter/material.dart';

class HomeBottomNavbar extends StatelessWidget {
  const HomeBottomNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home_outlined,
            label: 'Overview',
            isSelected: false,
          ),
          _buildNavItem(
            icon: Icons.fitness_center_outlined,
            label: 'Fitness',
            isSelected: false,
          ),
          _buildNavItem(
            icon: Icons.self_improvement_outlined,
            label: 'Yoga',
            isSelected: true,
          ),
          _buildNavItem(
            icon: Icons.sports_gymnastics_outlined,
            label: 'Gym',
            isSelected: false,
          ),
          _buildNavItem(
            icon: Icons.directions_run_outlined,
            label: 'Running',
            isSelected: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? const Color(0xFFDBF500) : Colors.grey,
          size: 24,
        ),
        const SizedBox(height: 4),
        Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFDBF500) : Colors.grey,
                fontSize: 12,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBF500),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
