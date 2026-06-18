import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/newsfeed/newsfeed_page.dart';

class YogaFeedCard extends StatefulWidget {
  const YogaFeedCard({super.key});

  @override
  State<YogaFeedCard> createState() => _YogaFeedCardState();
}

class _YogaFeedCardState extends State<YogaFeedCard> {
  List<Map<String, dynamic>> _feedItems = [
    {
      'id': 1,
      'title': 'Workout of the Day (WOD)',
      'description': 'Quick reels or carousels showing daily workout routines.',
      'image': null,
    },
    {
      'id': 2,
      'title': 'Yoga for Beginners',
      'description': 'Essential poses to start your yoga journey.',
      'image': null,
    },
    {
      'id': 3,
      'title': 'Meditation Tips',
      'description': 'Learn how to calm your mind in 5 minutes.',
      'image': null,
    },
  ];

  void _removeFeedItem(int id) {
    setState(() {
      _feedItems.removeWhere((item) => item['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'News Feed',
              style: TextStyle(
                color: context.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewsfeedPage(),
                  ),
                );
              },
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: context.textColor,
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_feedItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.cardBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.feed_outlined,
                  size: 48,
                  color: context.subtextColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'No feed items',
                  style: TextStyle(
                    color: context.subtextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ..._feedItems.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: context.cardBgColor,
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section - No Expanded
                      Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? const Color(0xff3a3a3a)
                              : Colors.grey[200],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: context.isDark ? themeColor : Colors.grey,
                        ),
                      ),
                      // Content Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? const Color(0xff2f2f2f)
                              : const Color(0xff2a2a2a),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['description'],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white70,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_circle_right_sharp,
                              color: themeColor,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Remove Button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeFeedItem(item['id']),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}