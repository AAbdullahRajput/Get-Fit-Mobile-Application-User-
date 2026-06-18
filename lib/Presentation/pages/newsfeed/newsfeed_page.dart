import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/widgets/newsfeed_card.dart';
import 'package:get_fit/Utils/constants.dart';

class NewsfeedPage extends StatefulWidget {
  const NewsfeedPage({super.key});

  @override
  State<NewsfeedPage> createState() => _NewsfeedPageState();
}

class _NewsfeedPageState extends State<NewsfeedPage> {
  static bool _hasLoaded = false;
  bool _isLoading = true;
  int selectedCategory = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> categories = [
    'All',
    'Health',
    'Nutrition',
    'Fitness',
    'Gym',
    'Trainer Tips'
  ];

  // Dummy newsfeed data
  final List<Map<String, dynamic>> newsfeedData = [
    {
      'id': '1',
      'title': 'Workout of the Day (WOD)',
      'category': 'Fitness',
      'description': 'Quick meal or carousel showing daily workout routines.',
      'content': 'Full workout routine for today including warmup, main sets, and cooldown. This is the detailed content that users will see when they click on the card.',
      'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&fit=crop',
      'date': 'Today',
      'author': 'Coach Mike',
    },
    {
      'id': '2',
      'title': 'Trainer Tips',
      'category': 'Trainer Tips',
      'description': 'Short videos from personal trainers giving workout or nutrition advice.',
      'content': 'Detailed tips from our expert trainers on proper form, nutrition, and recovery strategies to maximize your results.',
      'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&fit=crop',
      'date': 'Yesterday',
      'author': 'Coach Sarah',
    },
    {
      'id': '3',
      'title': 'Healthy and nutritious food',
      'category': 'Nutrition',
      'description': 'Before & after photos with short testimonials.',
      'content': 'Discover the best foods for muscle recovery, weight loss, and overall health. Includes recipes and meal prep tips.',
      'imageUrl': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&fit=crop',
      'date': '2 days ago',
      'author': 'Nutrition Expert',
    },
    {
      'id': '4',
      'title': '5 advantages of gym exercise',
      'category': 'Health',
      'description': 'Regular workouts strengthen your heart, muscles, and bones.',
      'content': 'Detailed breakdown of 5 key benefits: 1) Heart health 2) Muscle strength 3) Bone density 4) Mental health 5) Weight management.',
      'imageUrl': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&fit=crop',
      'date': '3 days ago',
      'author': 'Health Expert',
    },
    {
      'id': '5',
      'title': 'Benefits of yoga with a partner',
      'category': 'Gym',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      'content': 'Partner yoga benefits: improved communication, deeper stretches, enhanced trust, and better coordination between partners.',
      'imageUrl': 'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?w=400&fit=crop',
      'date': '5 days ago',
      'author': 'Yoga Instructor',
    },
    {
      'id': '6',
      'title': 'Healthy and nutritious food tips',
      'category': 'Nutrition',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      'content': 'Essential nutrition tips: macronutrient balance, meal timing, hydration strategies, and supplement recommendations.',
      'imageUrl': 'https://images.unsplash.com/photo-1617922001439-4a2e6562f328?w=400&fit=crop',
      'date': '1 week ago',
      'author': 'Dietician',
    },
  ];

  List<Map<String, dynamic>> get filteredNewsfeed {
    var result = newsfeedData;
    
    // Filter by category
    if (selectedCategory != 0) {
      result = result
          .where((item) => item['category'] == categories[selectedCategory])
          .toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((item) =>
              item['title']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item['category']!.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    return result;
  }

  @override
  void initState() {
    super.initState();
    _hasLoaded = true;
    _isLoading = false;
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'News Feed',
                style: TextStyle(
                  fontSize: 28,
                  color: context.isDark ? themeColor : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: context.cardBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: context.textColor),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search news...',
                    hintStyle: TextStyle(color: context.subtextColor),
                    border: InputBorder.none,
                    suffixIcon: Icon(
                      Icons.search,
                      color: context.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category Filter
            SizedBox(
              height: 35,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final selected = selectedCategory == index;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => selectedCategory = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? themeColor : context.cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: selected
                            ? null
                            : Border.all(
                                color: context.isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                      ),
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          color: selected ? Colors.black : context.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Result count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${filteredNewsfeed.length} posts',
                style: TextStyle(
                  color: context.subtextColor,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Newsfeed List
            Expanded(
              child: RefreshIndicator(
                color: themeColor,
                backgroundColor: context.cardBgColor,
                displacement: 100,
                onRefresh: _onRefresh,
                child: _isLoading
                    ? _buildSkeleton(context)
                    : _buildList(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (filteredNewsfeed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: context.subtextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No posts found',
              style: TextStyle(
                color: context.subtextColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter',
              style: TextStyle(
                color: context.subtextColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredNewsfeed.length,
      itemBuilder: (context, index) {
        final item = filteredNewsfeed[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: NewfeedCard(
            id: item['id'] ?? '',
            title: item['title'] ?? '',
            description: item['description'] ?? '',
            category: item['category'] ?? '',
            imageUrl: item['imageUrl'],
            author: item['author'] ?? '',
            date: item['date'] ?? '',
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ShimmerWidget(
            child: Container(
              height: 168,
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xff3a3a3a)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    height: 84,
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? const Color(0xff4a4a4a)
                          : Colors.grey.shade400,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 14,
                            decoration: BoxDecoration(
                              color: context.isDark
                                  ? const Color(0xff4a4a4a)
                                  : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 160,
                            height: 12,
                            decoration: BoxDecoration(
                              color: context.isDark
                                  ? const Color(0xff4a4a4a)
                                  : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 180,
                            height: 10,
                            decoration: BoxDecoration(
                              color: context.isDark
                                  ? const Color(0xff4a4a4a)
                                  : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 120,
                            height: 10,
                            decoration: BoxDecoration(
                              color: context.isDark
                                  ? const Color(0xff4a4a4a)
                                  : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  const _ShimmerWidget({required this.child});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}