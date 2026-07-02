import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class YogaCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool isUnlocked;
  final VoidCallback onTap;

  const YogaCourseCard({
    super.key,
    required this.course,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final instructor = course['yoga_instructors'] as Map<String, dynamic>?;
    final isPaid = course['_kind'] == 'paid' ||
        (course['_kind'] == null &&
            (course['price'] as num?) != null &&
            (course['price'] as num) > 0);
    final title = course['title'] ?? '';
    final authorName = instructor?['name'] ?? '';
    final imageUrl = course['image_url'] ?? '';
    final duration = course['duration_minutes']?.toString() ?? '';
    final level = course['level'] ?? '';
    final price = (course['price'] as num?)?.toStringAsFixed(0) ?? '0';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              child: Stack(children: [
                Image.network(
                  imageUrl,
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 110,
                    height: 110,
                    color: context.isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Icon(Icons.self_improvement, color: context.subtextColor),
                  ),
                ),
                if (isPaid && !isUnlocked)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Icon(Icons.lock_outline, color: Colors.white, size: 26),
                    ),
                  ),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPaid ? Colors.orange.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPaid ? '\$$price' : 'Free',
                          style: TextStyle(
                            color: isPaid ? Colors.orange : Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(title,
                        style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (authorName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('by $authorName', style: TextStyle(color: context.subtextColor, fontSize: 12)),
                    ],
                    const SizedBox(height: 6),
                    Row(children: [
                      if (level.isNotEmpty) Text(level, style: TextStyle(color: context.subtextColor, fontSize: 11)),
                      if (level.isNotEmpty && duration.isNotEmpty) const Text(' · '),
                      if (duration.isNotEmpty) Text('$duration min', style: TextStyle(color: context.subtextColor, fontSize: 11)),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}