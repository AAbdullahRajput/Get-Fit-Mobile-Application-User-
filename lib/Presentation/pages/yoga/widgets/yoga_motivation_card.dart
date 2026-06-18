import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class YogaMotivationCard extends StatefulWidget {
  const YogaMotivationCard({super.key});

  @override
  State<YogaMotivationCard> createState() => _YogaMotivationCardState();
}

class _YogaMotivationCardState extends State<YogaMotivationCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _motivations = [
    {
      'title': "Don't break the chain",
      'subtitle': "You've done 3 of 5 workouts this week.",
      'icon': Icons.bubble_chart_rounded,
      'color': themeColor,
    },
    {
      'title': "You're doing great!",
      'subtitle': "Keep pushing your limits everyday.",
      'icon': Icons.emoji_events,
      'color': Colors.orange,
    },
    {
      'title': "Stay consistent",
      'subtitle': "Small steps lead to big results.",
      'icon': Icons.trending_up,
      'color': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _motivations.length,
            itemBuilder: (context, index) {
              final item = _motivations[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: item['color'],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['subtitle'],
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              item['icon'],
                              color: Colors.black54,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: Container(
                          color: Colors.black12,
                          child: Image.asset(
                            'assets/home/yoga-handclosed-big-img.jpg',
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.image,
                                color: Colors.white54,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Dot Indicators
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _motivations.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.black
                        : Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}