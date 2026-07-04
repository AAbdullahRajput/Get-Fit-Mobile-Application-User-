import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/newsfeed/newsfeed_page.dart';
import 'package:get_fit/Presentation/pages/newsfeed/newsfeed_detail_page.dart';

class YogaFeedCard extends StatefulWidget {
  const YogaFeedCard({super.key});

  @override
  State<YogaFeedCard> createState() => _YogaFeedCardState();
}

class _YogaFeedCardState extends State<YogaFeedCard> {
  List<Map<String, dynamic>> _savedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    final saved = await SupabaseService.getSavedNewsfeedItems();
    if (mounted) {
      setState(() {
        _savedItems = saved;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeItem(String newsfeedItemId) async {
    try {
      await SupabaseService.unsaveNewsfeedItem(newsfeedItemId);
      setState(() {
        _savedItems.removeWhere(
            (item) => (item['newsfeed_items']?['id']) == newsfeedItemId);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove. Try again.')),
        );
      }
    }
  }

  void _goToFeedPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewsfeedPage()),
    ).then((_) => _loadFeed());
  }

  bool get _isEmpty => _savedItems.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Added Feed',
              style: TextStyle(
                color: context.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: _goToFeedPage,
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: context.textColor,
                size: 28,
              ),
            ),
          ],
        ),
        if (!_isEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: context.subtextColor, size: 13),
              const SizedBox(width: 4),
              Text(
                'Items are removed automatically 2 days after adding',
                style: TextStyle(color: context.subtextColor, fontSize: 11),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),

        if (_isLoading)
          _buildSkeleton(context)
        else if (_isEmpty)
          GestureDetector(
            onTap: _goToFeedPage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: context.cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: themeColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark_border_rounded,
                        color: themeColor, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nothing here yet',
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap to add articles to your feed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.subtextColor,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._savedItems.map((item) => _buildSavedCard(context, item)),
      ],
    );
  }

  Widget _buildSavedCard(BuildContext context, Map<String, dynamic> saved) {
    final article = saved['newsfeed_items'] as Map<String, dynamic>?;
    if (article == null) return const SizedBox.shrink();

    final id = article['id'] as String;
    final title = article['title'] as String? ?? '';
    final description = article['description'] as String? ?? '';
    final imageUrl = article['image_url'] as String? ?? '';
    final category = article['category'] as String? ?? '';
    final addedAt = DateTime.tryParse(saved['added_at'] as String? ?? '');
    final expiresIn = addedAt != null
        ? const Duration(days: 2) - DateTime.now().difference(addedAt)
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewsfeedDetailPage(
              id: id,
              title: title,
              description: description,
              category: category,
              imageUrl: imageUrl,
              author: article['author'] as String? ?? '',
              date: '',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeColor.withOpacity(0.15)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(context),
                        )
                      : _imageFallback(context),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 44, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                          color: themeColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 44, 0),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: context.textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: Text(
                    description,
                    style: TextStyle(color: context.subtextColor, fontSize: 12, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (expiresIn != null && !expiresIn.isNegative)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Text(
                      _formatExpiry(expiresIn),
                      style: TextStyle(
                        color: expiresIn.inHours < 6
                            ? Colors.orangeAccent
                            : context.subtextColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeItem(id),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatExpiry(Duration d) {
    if (d.inHours >= 1) return 'Removes in ${d.inHours}h';
    return 'Removes in ${d.inMinutes}m';
  }

  Widget _imageFallback(BuildContext context) {
    return Container(
      height: 140,
      color: context.isDark ? const Color(0xff3a3a3a) : Colors.grey[200],
      child: Icon(Icons.image_outlined, color: context.subtextColor, size: 48),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => _ShimmerWidget(
          child: Container(
            height: 240,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: context.isDark ? const Color(0xff3a3a3a) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
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
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _animation, child: widget.child);
}