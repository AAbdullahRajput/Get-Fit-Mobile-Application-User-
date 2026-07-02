import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class NewsfeedPage extends StatefulWidget {
  const NewsfeedPage({super.key});

  @override
  State<NewsfeedPage> createState() => _NewsfeedPageState();
}

class _NewsfeedPageState extends State<NewsfeedPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategory = 0;
  final List<String> _categories = ['Health', 'Nutrition', 'Fitness', 'Gym', 'Yoga'];

  // Placeholder data — swap for a real Supabase table once decided.
  final List<Map<String, dynamic>> _feedItems = [
    {
      'title': 'Workout of the Day (WOD)',
      'description': 'Quick reels or carousels showing daily workout routines.',
      'category': 'Fitness',
      'image_url': '',
    },
    {
      'title': 'Trainer Tips',
      'description': 'Short videos from personal trainers giving workout or nutrition advice.',
      'category': 'Fitness',
      'image_url': '',
    },
    {
      'title': 'Healthy and nutritious food',
      'description': 'Before & after photos with short testimonials.',
      'category': 'Nutrition',
      'image_url': '',
    },
  ];

  final List<Map<String, dynamic>> _otherFeeds = [
    {
      'title': 'Benefits of yoga with a partner',
      'description':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. In diam eros, maximus eu mi eu, posuere iaculis nulla.',
      'image_url': '',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredItems {
    var items = _feedItems;
    if (_selectedCategory != 0 && _selectedCategory <= _categories.length) {
      // "Health" (index 0) shows all for now since it's the umbrella tag
      final cat = _categories[_selectedCategory];
      items = items.where((i) => i['category'] == cat).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items
          .where((i) =>
              (i['title'] as String).toLowerCase().contains(q) ||
              (i['description'] as String).toLowerCase().contains(q))
          .toList();
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
              child: Row(
                children: [
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
                  Text(
                    'My Feed',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: context.cardBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: context.textColor),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: context.subtextColor, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: context.subtextColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'News Feed',
                      style: TextStyle(
                        color: context.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category chips
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, i) {
                          final selected = _selectedCategory == i;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = i),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? themeColor : context.cardBgColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _categories[i],
                                style: TextStyle(
                                  color: selected ? Colors.black : context.subtextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // News feed list
                    if (_filteredItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No feed items yet',
                            style: TextStyle(color: context.subtextColor, fontSize: 14),
                          ),
                        ),
                      )
                    else
                      ..._filteredItems.map((item) => _buildFeedCard(context, item)),

                    const SizedBox(height: 24),

                    // Other feeds
                    if (_otherFeeds.isNotEmpty) ...[
                      Text(
                        'Other Feeds',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 230,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _otherFeeds.length,
                          itemBuilder: (context, i) =>
                              _buildOtherFeedCard(context, _otherFeeds[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedCard(BuildContext context, Map<String, dynamic> item) {
    final imageUrl = item['image_url'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(context),
                  )
                : _imagePlaceholder(context),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? '',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['description'] ?? '',
                        style: TextStyle(color: context.subtextColor, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_outward, color: Colors.black, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherFeedCard(BuildContext context, Map<String, dynamic> item) {
    final imageUrl = item['image_url'] as String? ?? '';
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(context, height: 110),
                  )
                : _imagePlaceholder(context, height: 110),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['title'] ?? '',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: themeColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_outward, color: Colors.black, size: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['description'] ?? '',
                  style: TextStyle(color: context.subtextColor, fontSize: 10, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context, {double height = 130}) {
    return Container(
      height: height,
      width: double.infinity,
      color: context.isDark ? Colors.grey[800] : Colors.grey[200],
      child: Icon(Icons.image_outlined, color: context.subtextColor, size: 40),
    );
  }
}