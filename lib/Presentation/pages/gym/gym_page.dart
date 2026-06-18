import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class GymPage extends StatefulWidget {
  const GymPage({super.key});

  @override
  State<GymPage> createState() => _GymPageState();
}

class _GymPageState extends State<GymPage> {
  int selectedCategory = 0;

  final List<String> categories = ['All', 'Chest', 'Back', 'Legs', 'Arms', 'Core'];

  final List<Map<String, dynamic>> exercises = [
    {
      'title': 'Bench Press',
      'category': 'Chest',
      'sets': '4 Sets',
      'reps': '12 Reps',
      'level': 'Intermediate',
      'icon': Icons.fitness_center,
    },
    {
      'title': 'Pull Ups',
      'category': 'Back',
      'sets': '3 Sets',
      'reps': '10 Reps',
      'level': 'Advanced',
      'icon': Icons.accessibility_new,
    },
    {
      'title': 'Squats',
      'category': 'Legs',
      'sets': '4 Sets',
      'reps': '15 Reps',
      'level': 'Beginner',
      'icon': Icons.directions_walk,
    },
    {
      'title': 'Bicep Curls',
      'category': 'Arms',
      'sets': '3 Sets',
      'reps': '12 Reps',
      'level': 'Beginner',
      'icon': Icons.sports_gymnastics,
    },
    {
      'title': 'Deadlift',
      'category': 'Back',
      'sets': '4 Sets',
      'reps': '8 Reps',
      'level': 'Advanced',
      'icon': Icons.fitness_center,
    },
    {
      'title': 'Plank',
      'category': 'Core',
      'sets': '3 Sets',
      'reps': '60 Secs',
      'level': 'Beginner',
      'icon': Icons.self_improvement,
    },
    {
      'title': 'Leg Press',
      'category': 'Legs',
      'sets': '4 Sets',
      'reps': '12 Reps',
      'level': 'Intermediate',
      'icon': Icons.directions_walk,
    },
    {
      'title': 'Tricep Dips',
      'category': 'Arms',
      'sets': '3 Sets',
      'reps': '15 Reps',
      'level': 'Intermediate',
      'icon': Icons.sports_gymnastics,
    },
  ];

  List<Map<String, dynamic>> get filteredExercises {
    if (selectedCategory == 0) return exercises;
    return exercises
        .where((e) => e['category'] == categories[selectedCategory])
        .toList();
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gym',
                    style: TextStyle(
                      color: context.isDark ? themeColor : Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.local_fire_department,
                            color: Colors.black, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '5 Day Streak',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Today's Goal Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Colors.black, size: 36),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Today's Goal",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Complete 4 exercises • Burn 600 Kcal",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _statCard(context, Icons.timer_outlined, '45 Min',
                      'Duration'),
                  const SizedBox(width: 12),
                  _statCard(context, Icons.local_fire_department_outlined,
                      '600 Kcal', 'Calories'),
                  const SizedBox(width: 12),
                  _statCard(context, Icons.fitness_center_outlined,
                      '8 Exer', 'Exercises'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category Filter
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                'Exercises',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 35,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final selected = selectedCategory == index;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => selectedCategory = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            selected ? themeColor : context.cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: selected
                            ? null
                            : Border.all(
                                color: context.isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                      ),
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          color: selected
                              ? Colors.black
                              : context.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Exercise List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredExercises.length,
                itemBuilder: (context, index) {
                  final exercise = filteredExercises[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: themeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            exercise['icon'] as IconData,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise['title'],
                                style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    exercise['sets'],
                                    style: TextStyle(
                                      color: context.subtextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    ' • ',
                                    style: TextStyle(
                                        color: context.subtextColor),
                                  ),
                                  Text(
                                    exercise['reps'],
                                    style: TextStyle(
                                      color: context.subtextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _levelColor(exercise['level'])
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            exercise['level'],
                            style: TextStyle(
                              color: _levelColor(exercise['level']),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: themeColor, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: context.textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: context.subtextColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}