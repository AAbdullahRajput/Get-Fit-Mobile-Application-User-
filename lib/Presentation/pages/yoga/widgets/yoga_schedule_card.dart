import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_detail_page.dart';
import 'package:get_fit/Utils/constants.dart';

class YogaScheduleCard extends StatelessWidget {
  final String timeSlot;

  const YogaScheduleCard({super.key, required this.timeSlot});

  @override
  Widget build(BuildContext context) {
    final yogaList = _getYogaList(timeSlot);
    
    if (yogaList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No yoga classes available for $timeSlot',
          style: TextStyle(
            color: context.subtextColor,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Best $timeSlot Yoga',
          style: TextStyle(
            color: context.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: yogaList.length,
            itemBuilder: (context, index) {
              final yoga = yogaList[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => YogaDetailPage(
                        title: yoga['title'],
                        time: yoga['time'],
                        description: yoga['description'],
                        imagePath: yoga['imagePath'],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: context.cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          image: DecorationImage(
                            image: AssetImage(yoga['imagePath']),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '4.8',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Content Section
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              yoga['title'],
                              style: TextStyle(
                                color: context.textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 10,
                                  color: context.subtextColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    yoga['time'],
                                    style: TextStyle(
                                      color: context.subtextColor,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: themeColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                yoga['level'],
                                style: TextStyle(
                                  color: themeColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
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
            },
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getYogaList(String timeSlot) {
    final allYoga = {
      'Morning': [
        {
          'title': 'Sunrise Flow',
          'time': '6:00 AM - 7:00 AM',
          'level': 'Beginner',
          'imagePath': 'assets/home/yoga-img-1.png',
          'description': 'Start your day with gentle stretching and breathing exercises.',
        },
        {
          'title': 'Morning Stretch',
          'time': '7:30 AM - 8:30 AM',
          'level': 'Intermediate',
          'imagePath': 'assets/home/yoga-img-2.png',
          'description': 'Wake up your body with energizing yoga poses.',
        },
        {
          'title': 'Energizing Yoga',
          'time': '9:00 AM - 10:00 AM',
          'level': 'Advanced',
          'imagePath': 'assets/home/yoga-img-3.png',
          'description': 'Powerful morning routine to boost your energy.',
        },
      ],
      'Afternoon': [
        {
          'title': 'Midday Reset',
          'time': '12:00 PM - 1:00 PM',
          'level': 'Beginner',
          'imagePath': 'assets/home/yoga-img-2.png',
          'description': 'Refresh your mind and body during lunch break.',
        },
        {
          'title': 'Power Yoga',
          'time': '2:00 PM - 3:00 PM',
          'level': 'Intermediate',
          'imagePath': 'assets/home/yoga-img-1.png',
          'description': 'Build strength and flexibility with dynamic poses.',
        },
        {
          'title': 'Afternoon Flow',
          'time': '4:00 PM - 5:00 PM',
          'level': 'Advanced',
          'imagePath': 'assets/home/yoga-img-3.png',
          'description': 'Challenging flow to push your limits.',
        },
      ],
      'Evening': [
        {
          'title': 'Evening Stretch',
          'time': '6:00 PM - 7:00 PM',
          'level': 'Beginner',
          'imagePath': 'assets/home/yoga-img-3.png',
          'description': 'Gentle stretches to release tension from the day.',
        },
        {
          'title': 'Sunset Yoga',
          'time': '7:30 PM - 8:30 PM',
          'level': 'Intermediate',
          'imagePath': 'assets/home/yoga-img-2.png',
          'description': 'Wind down with calming yoga postures.',
        },
        {
          'title': 'Night Relaxation',
          'time': '9:00 PM - 10:00 PM',
          'level': 'Beginner',
          'imagePath': 'assets/home/yoga-img-1.png',
          'description': 'Deep relaxation and breathing for better sleep.',
        },
      ],
    };
    return allYoga[timeSlot] ?? [];
  }
}