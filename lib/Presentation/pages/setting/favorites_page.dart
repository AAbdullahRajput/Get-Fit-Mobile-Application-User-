import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  int selectedIndex = 0;

  final List<String> categories = ['All', 'Video', 'Article'];

  final List<Map<String, dynamic>> favoriteItems = const [
    {
      'title': 'Upper Body',
      'duration': '60 Minutes',
      'exercises': '5 Exercises',
      'calories': '1200 Kcal',
      'image': 'https://picsum.photos/200',
    },
    {
      'title': 'Boost Energy And Vitality',
      'duration': '45 Minutes',
      'exercises': '8 Exercises',
      'calories': '800 Kcal',
      'image': 'https://picsum.photos/201',
    },
    {
      'title': 'Pull Out Blast',
      'duration': '30 Minutes',
      'exercises': '10 Exercises',
      'calories': '1210 Kcal',
      'image': 'https://picsum.photos/202',
    },
    {
      'title': 'Lower Body',
      'duration': '40 Minutes',
      'exercises': '6 Exercises',
      'calories': '900 Kcal',
      'image': 'https://picsum.photos/203',
    },
    {
      'title': 'Avocado And Egg Toast',
      'duration': '15 Minutes',
      'exercises': '3 Steps',
      'calories': '450 Kcal',
      'image': 'https://picsum.photos/204',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Favorites',
                    style: TextStyle(
                      color: context.isDark ? themeColor : Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category Slider
                  SizedBox(
                    height: 35,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: selectedIndex == index
                                  ? themeColor
                                  : context.cardBgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: selectedIndex == index
                                  ? null
                                  : Border.all(
                                      color: context.isDark
                                          ? Colors.transparent
                                          : Colors.grey.shade300,
                                    ),
                            ),
                            child: Center(
                              child: Text(
                                categories[index],
                                style: TextStyle(
                                  color: selectedIndex == index
                                      ? Colors.black
                                      : context.textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Favorites List
                  Expanded(
                    child: ListView.builder(
                      itemCount: favoriteItems.length,
                      itemBuilder: (context, index) {
                        final item = favoriteItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: context.cardBgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                child: Image.network(
                                  item['image'],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 120,
                                      height: 120,
                                      color: context.isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[300],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: themeColor,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['title'],
                                              style: TextStyle(
                                                color: context.textColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.favorite,
                                            color: context.isDark
                                                ? themeColor
                                                : Colors.red,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 16,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.timer_outlined,
                                                color: context.subtextColor,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                item['duration'],
                                                style: TextStyle(
                                                  color: context.subtextColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '•',
                                            style: TextStyle(
                                                color: context.subtextColor),
                                          ),
                                          Text(
                                            item['exercises'],
                                            style: TextStyle(
                                              color: context.subtextColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item['calories'],
                                        style: TextStyle(
                                          color: context.isDark
                                              ? themeColor
                                              : Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Back button overlay
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                    backgroundColor: Colors.black54,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
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