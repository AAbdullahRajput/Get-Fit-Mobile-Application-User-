import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/newsfeed/newsfeed_page.dart';

class YogaFeedCard extends StatefulWidget {
  const YogaFeedCard({super.key});

  @override
  State<YogaFeedCard> createState() => _YogaFeedCardState();
}

class _YogaFeedCardState extends State<YogaFeedCard> {
  List<Map<String, dynamic>> _yogaFeedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    final yogaRaw = await SupabaseService.getUserFeedClasses();

    // Enrich yoga items with class details
    final List<Map<String, dynamic>> enrichedYoga = [];
    for (final item in yogaRaw) {
      final classId = item['class_id'] as String? ?? '';
      if (classId.isEmpty) continue;
      try {
        final cls = await SupabaseService.client
            .from('instructor_paid_classes')
            .select()
            .eq('id', classId)
            .maybeSingle();
        Map<String, dynamic>? instructor;
        if (cls != null && cls['instructor_id'] != null) {
          instructor = await SupabaseService.client
              .from('yoga_instructors')
              .select('name, specialty, image_url')
              .eq('id', cls['instructor_id'])
              .maybeSingle();
        }
        enrichedYoga.add({
          ...item,
          'instructor_paid_classes': cls,
          'yoga_instructors': instructor,
        });
      } catch (_) {
        enrichedYoga.add(item);
      }
    }

    if (mounted) {
      setState(() {
        _yogaFeedItems = enrichedYoga;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeYogaItem(String classId) async {
    try {
      await SupabaseService.removeClassFromFeed(classId);
      setState(() {
        _yogaFeedItems.removeWhere((item) => item['class_id'] == classId);
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

  bool get _isEmpty => _yogaFeedItems.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
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
        const SizedBox(height: 12),

        // Loading
        if (_isLoading)
          _buildSkeleton(context)

        // Empty state
        else if (_isEmpty)
          GestureDetector(
            onTap: _goToFeedPage,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
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
                    'Tap to add sessions to your feed.',
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

        else ...[
          // ── YOGA FEED ITEMS ─────────────────────────
          ..._yogaFeedItems
              .map((item) => _buildYogaFeedCard(context, item)),
        ],
      ],
    );
  }

  // ── YOGA FEED CARD ────────────────────────────

  Widget _buildYogaFeedCard(
      BuildContext context, Map<String, dynamic> item) {
    final cls =
        item['instructor_paid_classes'] as Map<String, dynamic>?;
    final instructor =
        item['yoga_instructors'] as Map<String, dynamic>?;
    final classId = item['class_id'] as String;
    final title = cls?['title'] ?? '';
    final description = cls?['description'] ?? '';
    final imageUrl = cls?['image_url'] ?? '';
    final level = cls?['level'] ?? '';
    final duration = cls?['duration_minutes']?.toString() ?? '';
    final classType = cls?['class_type'] ?? 'guide';
    final instructorName = instructor?['name'] ?? '';
    final instructorSpecialty = instructor?['specialty'] ?? '';
    final instructorImage = instructor?['image_url'] ?? '';

    return Container(
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
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imageFallback(context),
                        )
                      : _imageFallback(context),
                ),

                // Badges row
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Row(
                    children: [
                      _badge(level, themeColor),
                      const SizedBox(width: 6),
                      _badge(classType, Colors.white24,
                          textColor: context.subtextColor),
                      const Spacer(),
                      Icon(Icons.timer_outlined,
                          color: context.subtextColor, size: 13),
                      const SizedBox(width: 3),
                      Text('$duration min',
                          style: TextStyle(
                              color: context.subtextColor,
                              fontSize: 11)),
                    ],
                  ),
                ),

                // Title + description
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 44, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            color: context.subtextColor,
                            fontSize: 12,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Instructor row
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: themeColor,
                        backgroundImage: instructorImage.isNotEmpty
                            ? NetworkImage(instructorImage)
                            : null,
                        child: instructorImage.isEmpty
                            ? const Icon(Icons.person,
                                color: Colors.black, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              instructorName,
                              style: TextStyle(
                                color: context.textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              instructorSpecialty,
                              style: TextStyle(
                                color: context.subtextColor,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: themeColor, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Remove button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeYogaItem(classId),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 15),
                ),
              ),
            ),
          ],
        ),
      );
  }

  // ── HELPERS ───────────────────────────────────

  Widget _imageFallback(BuildContext context) {
    return Container(
      height: 160,
      color: context.isDark
          ? const Color(0xff3a3a3a)
          : Colors.grey[200],
      child: Icon(Icons.play_circle_outline,
          color: context.subtextColor, size: 48),
    );
  }

  Widget _badge(String label, Color bgColor,
      {Color textColor = Colors.black}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.bold),
      ),
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
              color: context.isDark
                  ? const Color(0xff3a3a3a)
                  : Colors.grey.shade300,
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
        vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(
            parent: _controller, curve: Curves.easeInOut));
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