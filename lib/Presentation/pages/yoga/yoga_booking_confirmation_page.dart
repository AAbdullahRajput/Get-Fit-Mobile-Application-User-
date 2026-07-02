import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class YogaBookingConfirmationPage extends StatelessWidget {
  final Map<String, dynamic> course;

  const YogaBookingConfirmationPage({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: themeColor, width: 2),
                ),
                child: const Icon(Icons.check_rounded,
                    color: themeColor, size: 52),
              ),
              const SizedBox(height: 24),

              const Text(
                'Purchase Confirmed!',
                style: TextStyle(
                    color: themeColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This course is now unlocked and ready to view.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.subtextColor, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),

              // Summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Course row
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            course['image_url'] ?? '',
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 52,
                              height: 52,
                              color: context.isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              child: Icon(Icons.self_improvement,
                                  color: context.subtextColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course['title'] ?? '',
                                style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (((course['yoga_instructors']
                                          as Map<String, dynamic>?)?['name'] ??
                                      '')
                                  .toString()
                                  .isNotEmpty)
                                Text(
                                  'by ${(course['yoga_instructors'] as Map<String, dynamic>?)?['name']}',
                                  style: TextStyle(
                                      color: context.subtextColor,
                                      fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(
                        color: context.isDark
                            ? Colors.white12
                            : Colors.grey.shade200,
                        height: 24),

                    _detailRow(context, Icons.monetization_on_outlined,
                        'Total Paid',
                        '\$${((course['price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}'),
                  ],
                ),
              ),

              const Spacer(),

              // Back to home button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    int count = 0;
                    Navigator.of(context).popUntil((route) {
                      return count++ >= 2;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: themeColor, size: 18),
        const SizedBox(width: 10),
        Text(label,
            style:
                TextStyle(color: context.subtextColor, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: context.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}