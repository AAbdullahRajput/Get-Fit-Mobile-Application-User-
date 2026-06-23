import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_write_review_page.dart';

class YogaReviewsPage extends StatefulWidget {
  final String instructorId;
  final String instructorName;
  final String rating;
  final VoidCallback? onReviewChanged;

  const YogaReviewsPage({
    super.key,
    required this.instructorId,
    required this.instructorName,
    required this.rating,
    this.onReviewChanged,
  });

  @override
  State<YogaReviewsPage> createState() => _YogaReviewsPageState();
}

class _YogaReviewsPageState extends State<YogaReviewsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allReviews = [];
  List<Map<String, dynamic>> _filtered = [];
  Map<String, dynamic>? _myReview;
  int _selectedIndex = 0;

  final List<String> _categories = ['Recent', 'Critical', 'Favourables'];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    final data =
        await SupabaseService.getYogaInstructorReviews(widget.instructorId);
    final myReview =
        await SupabaseService.getMyYogaReview(widget.instructorId);
    if (mounted) {
      setState(() {
        _allReviews = data;
        _myReview = myReview;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async => _loadReviews();

  void _applyFilter() {
    switch (_selectedIndex) {
      case 0:
        _filtered = List.from(_allReviews);
        break;
      case 1:
        _filtered = _allReviews
            .where((r) => (r['rating'] as num).toDouble() <= 3.0)
            .toList();
        break;
      case 2:
        _filtered = _allReviews
            .where((r) => (r['rating'] as num).toDouble() >= 4.0)
            .toList();
        break;
    }
  }

  Map<int, int> get _distribution {
    final map = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _allReviews) {
      final star = (r['rating'] as num).round().clamp(1, 5);
      map[star] = (map[star] ?? 0) + 1;
    }
    return map;
  }

  double get _avgRating {
    if (_allReviews.isEmpty) return double.tryParse(widget.rating) ?? 0.0;
    final sum = _allReviews
        .map((r) => (r['rating'] as num).toDouble())
        .reduce((a, b) => a + b);
    return sum / _allReviews.length;
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Review',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to delete your review? This cannot be undone.',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade400)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await SupabaseService.deleteYogaReview(
                    instructorId: widget.instructorId);
                widget.onReviewChanged?.call();
                _loadReviews();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Failed to delete review'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
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
                    child:
                        const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Reviews',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                widget.instructorName,
                style: TextStyle(
                    color: context.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),

            // Filter tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: context.cardBgColor,
              ),
              height: 45,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () => setState(() {
                          _selectedIndex = index;
                          _applyFilter();
                        }),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: _selectedIndex == index
                                ? themeColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(
                              _categories[index],
                              style: TextStyle(
                                color: _selectedIndex == index
                                    ? Colors.black
                                    : context.textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rating overview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(
                        _avgRating.toStringAsFixed(1),
                        style: TextStyle(
                          color: context.isDark
                              ? themeColor
                              : Colors.black87,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < _avgRating.round()
                                ? Icons.star
                                : Icons.star_border,
                            color: themeColor,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${_allReviews.length} reviews',
                          style: TextStyle(
                              color: context.subtextColor, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [5, 4, 3, 2, 1].map((star) {
                        final count = _distribution[star] ?? 0;
                        final total = _allReviews.length;
                        final fraction =
                            total == 0 ? 0.0 : count / total;
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Text('$star',
                                  style: TextStyle(
                                      color: context.subtextColor,
                                      fontSize: 12)),
                              const SizedBox(width: 6),
                              Icon(Icons.star,
                                  color: themeColor, size: 12),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: fraction,
                                    minHeight: 6,
                                    backgroundColor: context.isDark
                                        ? const Color(0xff3a3a3a)
                                        : Colors.grey.shade300,
                                    valueColor:
                                        AlwaysStoppedAnimation(themeColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 20,
                                child: Text('$count',
                                    style: TextStyle(
                                        color: context.subtextColor,
                                        fontSize: 11)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: RefreshIndicator(
                color: context.subtextColor,
                backgroundColor: context.cardBgColor,
                displacement: 100,
                onRefresh: _onRefresh,
                child: _isLoading
                    ? _buildSkeleton(context)
                    : _buildList(context),
              ),
            ),

            // Write review button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => YogaWriteReviewPage(
                        instructorId: widget.instructorId,
                        instructorName: widget.instructorName,
                        existing: _myReview,
                        onSubmitted: () {
                          widget.onReviewChanged?.call();
                          _loadReviews();
                        },
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: Text(
                  _myReview != null
                      ? 'Edit Your Review'
                      : 'Write a Review',
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          _allReviews.isEmpty
              ? 'No reviews yet. Be the first!'
              : 'No reviews in this category.',
          style:
              TextStyle(color: context.subtextColor, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final r = _filtered[index];
        final isMe =
            r['user_id'] == SupabaseService.currentUser?.id;
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: GestureDetector(
            onLongPress: isMe
                ? () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF2C2C2C),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20)),
                      ),
                      builder: (_) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius:
                                      BorderRadius.circular(2)),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.edit,
                                  color: themeColor),
                              title: const Text('Edit Review',
                                  style:
                                      TextStyle(color: Colors.white)),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => YogaWriteReviewPage(
                                      instructorId: widget.instructorId,
                                      instructorName:
                                          widget.instructorName,
                                      existing: r,
                                      onSubmitted: () {
                                        widget.onReviewChanged?.call();
                                        _loadReviews();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent),
                              title: const Text('Delete Review',
                                  style: TextStyle(
                                      color: Colors.redAccent)),
                              onTap: () {
                                Navigator.pop(context);
                                _confirmDelete();
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  }
                : null,
            child: Card(
              color: context.cardBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isMe
                    ? BorderSide(
                        color: themeColor.withOpacity(0.5), width: 1.5)
                    : BorderSide.none,
              ),
              elevation: context.isDark ? 0 : 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: themeColor,
                          backgroundImage: ((r['users']?['avatar_url'] ??
                                          r['avatar_url'] ??
                                          '')
                                      .toString()
                                      .isNotEmpty)
                              ? NetworkImage(r['users']?['avatar_url'] ??
                                  r['avatar_url'])
                              : null,
                          child: ((r['users']?['avatar_url'] ??
                                          r['avatar_url'] ??
                                          '')
                                      .toString()
                                      .isEmpty)
                              ? const Icon(Icons.person,
                                  color: Colors.black, size: 22)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isMe
                                        ? 'You'
                                        : (r['username'] ?? 'User'),
                                    style: TextStyle(
                                        color: context.textColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                          color: themeColor,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  6)),
                                      child: const Text('You',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ),
                                  ],
                                  const SizedBox(width: 6),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: themeColor,
                                        borderRadius:
                                            BorderRadius.circular(6)),
                                    child: Text(
                                      (r['rating'] as num)
                                          .toStringAsFixed(1),
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < (r['rating'] as num).round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: themeColor,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDate(r['created_at']),
                          style: TextStyle(
                              color: context.subtextColor,
                              fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      r['review_text'] ?? '',
                      style: TextStyle(
                          color: context.subtextColor,
                          fontSize: 13,
                          height: 1.4),
                    ),
                    if (r['updated_at'] != null &&
                        r['updated_at'] != r['created_at'])
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Edited ${_formatDate(r['updated_at'])}',
                          style: TextStyle(
                              color: context.subtextColor
                                  .withOpacity(0.5),
                              fontSize: 10,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return '1d ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      if (diff.inDays < 30)
        return '${(diff.inDays / 7).floor()}w ago';
      if (diff.inDays < 365)
        return '${(diff.inDays / 30).floor()}mo ago';
      return '${(diff.inDays / 365).floor()}y ago';
    } catch (_) {
      return '';
    }
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: _ShimmerWidget(
          child: Container(
            height: 100,
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