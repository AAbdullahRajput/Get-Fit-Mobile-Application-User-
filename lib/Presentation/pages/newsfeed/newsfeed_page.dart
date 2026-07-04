import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/newsfeed/newsfeed_detail_page.dart';

class NewsfeedPage extends StatefulWidget {
  const NewsfeedPage({super.key});

  @override
  State<NewsfeedPage> createState() => _NewsfeedPageState();
}

class _NewsfeedPageState extends State<NewsfeedPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategory = 0;

  // "Health" acts as the umbrella "All" tab — matches your existing category
  // set stored in newsfeed_items.category.
  final List<String> _categories = ['Health', 'Nutrition', 'Fitness', 'Gym', 'Yoga'];

  bool _isLoading = true;
  List<Map<String, dynamic>> _feedItems = [];
  List<Map<String, dynamic>> _otherFeeds = [];
  Set<String> _savedIds = {};

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);

    final category = _selectedCategory == 0 ? null : _categories[_selectedCategory];
    final items = await SupabaseService.getNewsfeedItems(category: category);
    final savedIds = await SupabaseService.getSavedNewsfeedItemIds();

    if (mounted) {
      setState(() {
        _feedItems = items;
        _otherFeeds = items.length > 6 ? items.sublist(6) : [];
        _savedIds = savedIds;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSave(String itemId) async {
    final isSaved = _savedIds.contains(itemId);
    setState(() {
      if (isSaved) {
        _savedIds.remove(itemId);
      } else {
        _savedIds.add(itemId);
      }
    });
    try {
      if (isSaved) {
        await SupabaseService.unsaveNewsfeedItem(itemId);
      } else {
        await SupabaseService.saveNewsfeedItem(itemId);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (isSaved) {
            _savedIds.add(itemId);
          } else {
            _savedIds.remove(itemId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update feed. Try again.')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    var items = _feedItems;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items
          .where((i) =>
              ((i['title'] as String?) ?? '').toLowerCase().contains(q) ||
              ((i['description'] as String?) ?? '').toLowerCase().contains(q))
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
                  const Spacer(),
                  IconButton(
                    onPressed: _loadFeed,
                    icon: Icon(Icons.refresh_rounded, color: context.textColor),
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
              child: RefreshIndicator(
                color: themeColor,
                onRefresh: _loadFeed,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                              onTap: () {
                                setState(() => _selectedCategory = i);
                                _loadFeed();
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 8),
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
                      if (_isLoading)
                        _buildSkeletonList(context)
                      else if (_filteredItems.isEmpty)
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
                        ..._filteredItems
                            .take(6)
                            .map((item) => _buildFeedCard(context, item)),

                      const SizedBox(height: 24),

                      // Other feeds
                      if (!_isLoading && _otherFeeds.isNotEmpty) ...[
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
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsfeedDetailPage(
          id: item['id']?.toString() ?? '',
          title: item['title'] as String? ?? '',
          description: item['description'] as String? ?? '',
          category: item['category'] as String? ?? '',
          imageUrl: item['image_url'] as String?,
          author: item['author'] as String? ?? item['source_name'] as String? ?? '',
          date: _formatDate(item['published_at'] as String?),
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Widget _buildFeedCard(BuildContext context, Map<String, dynamic> item) {
    final imageUrl = item['image_url'] as String? ?? '';
    final itemId = item['id'] as String;
    final isSaved = _savedIds.contains(itemId);
    return GestureDetector(
      onTap: () => _openDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          headers: const {
                            'User-Agent':
                                'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
                            'Referer': 'https://breakingmuscle.com/',
                          },
                          errorBuilder: (_, error, ___) => _imagePlaceholder(context),
                        )
                      : _imagePlaceholder(context),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleSave(itemId),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved ? themeColor : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['description'] ?? '',
                          style: TextStyle(color: context.subtextColor, fontSize: 12, height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildOtherFeedCard(BuildContext context, Map<String, dynamic> item) {
    final imageUrl = item['image_url'] as String? ?? '';
    return GestureDetector(
      onTap: () => _openDetail(item),
      child: Container(
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
                      headers: const {
                        'User-Agent':
                            'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
                        'Referer': 'https://breakingmuscle.com/',
                      },
                      errorBuilder: (_, error, ___) {
                        debugPrint('❌ OtherFeedCard image failed: $imageUrl | $error');
                        return _imagePlaceholder(context, height: 110);
                      },
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

  Widget _buildSkeletonList(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 220,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xff2c2c2c) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}