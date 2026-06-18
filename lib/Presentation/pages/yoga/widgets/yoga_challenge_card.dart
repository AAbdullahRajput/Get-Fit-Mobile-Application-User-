import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/yoga/challenge/weekly_challenge_landing_page.dart';

class YogaChallengeCard extends StatelessWidget {
  const YogaChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WeeklyChallengeLandingPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: themeColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Challenge',
                          style: TextStyle(
                            color: context.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Complete 7 days of yoga',
                          style: TextStyle(
                            color: context.subtextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '3/7',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress Bar
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.isDark ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                widthFactor: 0.43,
                child: Container(
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _dayChip(context, 'M', true),
                _dayChip(context, 'T', true),
                _dayChip(context, 'W', true),
                _dayChip(context, 'T', false),
                _dayChip(context, 'F', false),
                _dayChip(context, 'S', false),
                _dayChip(context, 'S', false),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'View all challenges →',
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Streak: 3 days',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayChip(BuildContext context, String day, bool completed) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: completed ? themeColor : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: completed ? themeColor : (context.isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
      ),
      child: Center(
        child: Text(
          day,
          style: TextStyle(
            color: completed ? Colors.black : context.subtextColor,
            fontSize: 11,
            fontWeight: completed ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}