import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class YogaDetailPage extends StatelessWidget {
  final Map<String, dynamic> yoga;

  const YogaDetailPage({super.key, required this.yoga});

  Color _levelColor(String level) {
    switch (level) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return themeColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = yoga['level'] ?? '';
    final rating = double.parse(yoga['rating'].toString());

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image with back button overlay
            Stack(
              children: [
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: Image.network(
                    yoga['image_url'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 280,
                      color: const Color(0xFF2C2C2C),
                      child: const Icon(Icons.self_improvement,
                          color: Colors.white38, size: 80),
                    ),
                  ),
                ),
                // Gradient over image
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          context.bgColor,
                        ],
                      ),
                    ),
                  ),
                ),
                // Back button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(10),
                        backgroundColor: Colors.black54,
                        elevation: 0,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
                // Free badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'FREE',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    yoga['title'] ?? '',
                    style: const TextStyle(
                        color: themeColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Badges row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _levelColor(level).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _levelColor(level).withOpacity(0.5)),
                        ),
                        child: Text(level,
                            style: TextStyle(
                                color: _levelColor(level),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      if ((yoga['category'] ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: themeColor.withOpacity(0.3)),
                          ),
                          child: Text(yoga['category'],
                              style: const TextStyle(
                                  color: themeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      const Spacer(),
                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                                color: context.textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Time + Duration
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          color: themeColor, size: 16),
                      const SizedBox(width: 8),
                      Text(yoga['class_time'] ?? '',
                          style: TextStyle(
                              color: context.subtextColor, fontSize: 14)),
                      const SizedBox(width: 16),
                      Icon(Icons.timer_outlined,
                          color: themeColor, size: 16),
                      const SizedBox(width: 8),
                      Text('${yoga['duration_minutes']} min',
                          style: TextStyle(
                              color: context.subtextColor, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text('About This Class',
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(yoga['description'] ?? '',
                      style: TextStyle(
                          color: context.subtextColor,
                          fontSize: 15,
                          height: 1.6)),
                  const SizedBox(height: 24),

                  // What You'll Learn
                  Text("What You'll Learn",
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _learnItem(context, 'Proper breathing techniques'),
                  _learnItem(context, 'Correct posture alignment'),
                  _learnItem(context, 'Mindfulness and focus'),
                  _learnItem(context, 'Flexibility and strength'),
                  const SizedBox(height: 24),

                  // Benefits
                  Text('Benefits',
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _benefitChip(context, 'Improves Flexibility'),
                      _benefitChip(context, 'Reduces Stress'),
                      _benefitChip(context, 'Builds Strength'),
                      _benefitChip(context, 'Better Sleep'),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Free class note
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: themeColor.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_open_outlined,
                            color: themeColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This is a free class available to all users. No booking required.',
                            style: TextStyle(
                                color: context.subtextColor,
                                fontSize: 13,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Start button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                        'Start Class',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _learnItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: themeColor, size: 14),
          ),
          const SizedBox(width: 12),
          Text(text,
              style:
                  TextStyle(color: context.textColor, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _benefitChip(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Text(text,
          style: TextStyle(color: context.textColor, fontSize: 13)),
    );
  }
}