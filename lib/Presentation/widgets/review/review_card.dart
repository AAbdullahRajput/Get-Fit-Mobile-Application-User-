import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: themeColor,
                child: const Icon(Icons.person, color: Colors.black),
              ),
              title: Text(
                'John Doe (4.5)',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 18,
                ),
              ),
              trailing: Text(
                "2d ago",
                style: TextStyle(
                  color: context.subtextColor,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: Text(
                "Great trainer! Helped me achieve my fitness goals in no time.",
                style: TextStyle(
                  color: context.subtextColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}