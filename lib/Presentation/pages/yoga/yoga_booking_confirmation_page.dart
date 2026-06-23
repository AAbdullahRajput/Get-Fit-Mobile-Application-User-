import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class YogaBookingConfirmationPage extends StatelessWidget {
  final Map<String, dynamic> instructor;
  final String displayDate;
  final int numSessions;
  final double totalPrice;

  const YogaBookingConfirmationPage({
    super.key,
    required this.instructor,
    required this.displayDate,
    required this.numSessions,
    required this.totalPrice,
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
                'Booking Confirmed!',
                style: TextStyle(
                    color: themeColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your yoga sessions have been booked successfully.',
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
                    // Instructor row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: themeColor,
                          backgroundImage:
                              (instructor['image_url'] ?? '').isNotEmpty
                                  ? NetworkImage(instructor['image_url'])
                                  : null,
                          child: (instructor['image_url'] ?? '').isEmpty
                              ? const Icon(Icons.self_improvement,
                                  color: Colors.black, size: 28)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                instructor['name'] ?? '',
                                style: TextStyle(
                                    color: context.textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                instructor['specialty'] ?? '',
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

                    _detailRow(context, Icons.calendar_today_outlined,
                        'Start Date', displayDate),
                    const SizedBox(height: 12),
                    _detailRow(context, Icons.self_improvement,
                        'Sessions', '$numSessions sessions'),
                    const SizedBox(height: 12),
                    _detailRow(context, Icons.monetization_on_outlined,
                        'Total Paid', '\$${totalPrice.toStringAsFixed(2)}'),
                  ],
                ),
              ),

              const Spacer(),

              // Back to home button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop all the way back to root
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
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