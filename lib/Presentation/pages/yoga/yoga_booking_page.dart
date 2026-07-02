import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_payment_page.dart';
import 'package:get_fit/Utils/constants.dart';

class YogaBookingPage extends StatelessWidget {
  final Map<String, dynamic> course;

  const YogaBookingPage({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final instructor = course['yoga_instructors'] as Map<String, dynamic>?;
    final title = course['title'] ?? '';
    final authorName = instructor?['name'] ?? '';
    final imageUrl = course['image_url'] ?? '';
    final description = course['description'] ?? '';
    final duration = course['duration_minutes']?.toString() ?? '';
    final level = course['level'] ?? '';
    final price = (course['price'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
              child: Row(children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                    backgroundColor: Colors.black54,
                    elevation: 0,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text('Buy Course',
                    style: TextStyle(
                        color: themeColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: context.isDark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          child: Icon(Icons.self_improvement,
                              color: context.subtextColor, size: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(title,
                        style: TextStyle(
                            color: context.textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    if (authorName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('by $authorName',
                          style: TextStyle(
                              color: context.subtextColor, fontSize: 14)),
                    ],
                    const SizedBox(height: 10),
                    Row(children: [
                      if (level.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(level,
                              style: const TextStyle(
                                  color: themeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      if (level.isNotEmpty && duration.isNotEmpty)
                        const SizedBox(width: 8),
                      if (duration.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.isDark
                                ? Colors.white10
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('$duration min',
                              style: TextStyle(
                                  color: context.subtextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ]),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text('About this course',
                          style: TextStyle(
                              color: context.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(description,
                          style: TextStyle(
                              color: context.subtextColor,
                              fontSize: 14,
                              height: 1.5)),
                    ],
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.cardBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total',
                              style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold)),
                          Text('\$${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: themeColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => YogaPaymentPage(
                                course: course,
                                price: price,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text(
                          'Proceed to Payment  •  \$${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}