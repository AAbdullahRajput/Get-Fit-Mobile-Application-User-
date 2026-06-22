import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class ReviewsPage extends StatefulWidget {
  final String trainerId;
  final String trainerName;
  final String rating;
  final VoidCallback? onReviewChanged;

  const ReviewsPage({
    super.key,
    required this.trainerId,
    required this.trainerName,
    required this.rating,
    this.onReviewChanged,
  });

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
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
    final data = await SupabaseService.getTrainerReviews(widget.trainerId);
    final myReview = await SupabaseService.getMyReview(widget.trainerId);
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
        _filtered = _allReviews.where((r) => (r['rating'] as num).toDouble() <= 3.0).toList();
        break;
      case 2:
        _filtered = _allReviews.where((r) => (r['rating'] as num).toDouble() >= 4.0).toList();
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
    final sum = _allReviews.map((r) => (r['rating'] as num).toDouble()).reduce((a, b) => a + b);
    return sum / _allReviews.length;
  }

  void _showWriteReviewSheet({Map<String, dynamic>? existing}) {
    double rating = existing != null ? (existing['rating'] as num).toDouble() : 5.0;
    final controller = TextEditingController(text: existing?['review_text'] ?? '');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                existing != null ? 'Edit Your Review' : 'Write a Review',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(widget.trainerName, style: TextStyle(color: themeColor, fontSize: 14)),
              const SizedBox(height: 20),
              const Text('Rating', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setSheet(() => rating = i + 1.0),
                  child: Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: themeColor, size: 36,
                  ),
                )),
              ),
              const SizedBox(height: 20),
              const Text('Your Review', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  controller: controller,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Share your experience...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    setSheet(() => isSubmitting = true);
                    try {
                      await SupabaseService.submitReview(
                        trainerId: widget.trainerId,
                        rating: rating,
                        reviewText: text,
                      );
                      if (!mounted) return;
                      Navigator.pop(sheetCtx);
                      widget.onReviewChanged?.call();
                      _loadReviews();
                    } catch (e) {
                      setSheet(() => isSubmitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Failed to submit review'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(
                          existing != null ? 'Update Review' : 'Submit Review',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete your review? This cannot be undone.',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await SupabaseService.deleteReview(trainerId: widget.trainerId);
                widget.onReviewChanged?.call();
                _loadReviews();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Failed to delete review'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 56),

                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    widget.trainerName,
                    style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Reviews',
                    style: TextStyle(color: themeColor, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),

                // Tabs
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
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color: _selectedIndex == index ? themeColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  _categories[index],
                                  style: TextStyle(
                                    color: _selectedIndex == index ? Colors.black : context.textColor,
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
                              color: context.isDark ? themeColor : Colors.black87,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: List.generate(5, (i) => Icon(
                              i < _avgRating.round() ? Icons.star : Icons.star_border,
                              color: themeColor, size: 16,
                            )),
                          ),
                          const SizedBox(height: 4),
                          Text('${_allReviews.length} reviews',
                              style: TextStyle(color: context.subtextColor, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [5, 4, 3, 2, 1].map((star) {
                            final count = _distribution[star] ?? 0;
                            final total = _allReviews.length;
                            final fraction = total == 0 ? 0.0 : count / total;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Text('$star', style: TextStyle(color: context.subtextColor, fontSize: 12)),
                                  const SizedBox(width: 6),
                                  Icon(Icons.star, color: themeColor, size: 12),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: fraction,
                                        minHeight: 6,
                                        backgroundColor: context.isDark ? const Color(0xff3a3a3a) : Colors.grey.shade300,
                                        valueColor: AlwaysStoppedAnimation(themeColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    width: 20,
                                    child: Text('$count', style: TextStyle(color: context.subtextColor, fontSize: 11)),
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
                    child: _isLoading ? _buildSkeleton(context) : _buildList(context),
                  ),
                ),

                // Write a Review button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: ElevatedButton(
                    onPressed: () => _showWriteReviewSheet(existing: _myReview),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    child: Text(
                      _myReview != null ? 'Edit Your Review' : 'Write a Review',
                      style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Back button
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
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          _allReviews.isEmpty ? 'No reviews yet. Be the first!' : 'No reviews in this category.',
          style: TextStyle(color: context.subtextColor, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final r = _filtered[index];
        final isMe = r['user_id'] == SupabaseService.currentUser?.id;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Card(
            color: context.cardBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isMe ? BorderSide(color: themeColor.withOpacity(0.5), width: 1.5) : BorderSide.none,
            ),
            elevation: context.isDark ? 0 : 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: themeColor,
                        backgroundImage: (r['avatar_url'] ?? '').toString().isNotEmpty
                            ? NetworkImage(r['avatar_url']) : null,
                        child: (r['avatar_url'] ?? '').toString().isEmpty
                            ? const Icon(Icons.person, color: Colors.black, size: 22) : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isMe ? 'You' : (r['username'] ?? 'User'),
                                  style: TextStyle(color: context.textColor, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('You', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                    (r['rating'] as num).toStringAsFixed(1),
                                    style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: List.generate(5, (i) => Icon(
                                i < (r['rating'] as num).round() ? Icons.star : Icons.star_border,
                                color: themeColor, size: 14,
                              )),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_formatDate(r['created_at']),
                              style: TextStyle(color: context.subtextColor, fontSize: 11)),
                          if (isMe) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _showWriteReviewSheet(existing: r),
                                  child: Icon(Icons.edit, color: themeColor, size: 16),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _confirmDelete,
                                  child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    r['review_text'] ?? '',
                    style: TextStyle(color: context.subtextColor, fontSize: 13, height: 1.4),
                  ),
                  if (r['updated_at'] != null && r['updated_at'] != r['created_at'])
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Edited ${_formatDate(r['updated_at'])}',
                        style: TextStyle(color: context.subtextColor.withOpacity(0.5), fontSize: 10, fontStyle: FontStyle.italic),
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

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return '1d ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
      return '${(diff.inDays / 365).floor()}y ago';
    } catch (_) { return ''; }
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: _ShimmerWidget(
          child: Container(
            height: 100,
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
  @override State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}
class _ShimmerWidgetState extends State<_ShimmerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => FadeTransition(opacity: _animation, child: widget.child);
}