import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class BookingConfirmationPage extends StatelessWidget {
  final String trainerName;
  final String trainerType;
  final double trainerRating;
  final String trainerAvatarUrl;
  final String displayDate;
  final String time;

  const BookingConfirmationPage({
    super.key,
    required this.trainerName,
    required this.trainerType,
    required this.trainerRating,
    required this.trainerAvatarUrl,
    required this.displayDate,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkmark + title
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.check, color: Colors.black, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text('Payment Completed!',
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "You've book a new appointment\nwith your trainers.",
                style: TextStyle(color: context.subtextColor, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),

              // Booking details card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trainer row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: themeColor,
                          backgroundImage: trainerAvatarUrl.isNotEmpty
                              ? NetworkImage(trainerAvatarUrl) : null,
                          child: trainerAvatarUrl.isEmpty
                              ? const Icon(Icons.person, color: Colors.black, size: 28) : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(trainerName,
                                  style: TextStyle(
                                      color: context.textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text(trainerType,
                                  style: TextStyle(
                                      color: context.subtextColor, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (trainerRating > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: themeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              trainerRating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Date
                    Text('Date',
                        style: TextStyle(
                            color: context.subtextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(displayDate,
                        style: TextStyle(
                            color: context.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),

                    // Time
                    Text('Time',
                        style: TextStyle(
                            color: context.subtextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(time,
                        style: TextStyle(
                            color: context.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              const Spacer(),

              // Done button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop all the way back to home
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}