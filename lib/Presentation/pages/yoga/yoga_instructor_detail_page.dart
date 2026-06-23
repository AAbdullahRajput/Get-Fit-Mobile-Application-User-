import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_reviews_page.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_booking_page.dart';
import 'package:get_fit/Presentation/widgets/reuseable_button.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class YogaInstructorDetailPage extends StatefulWidget {
  final Map<String, dynamic> instructor;

  const YogaInstructorDetailPage({super.key, required this.instructor});

  @override
  State<YogaInstructorDetailPage> createState() =>
      _YogaInstructorDetailPageState();
}

class _YogaInstructorDetailPageState extends State<YogaInstructorDetailPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic>? _myReview;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final instructorId = widget.instructor['id'] as String;
    final reviews = await SupabaseService.getYogaInstructorReviews(instructorId);
    final myReview = await SupabaseService.getMyYogaReview(instructorId);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _myReview = myReview;
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async => _loadData();

  @override
  Widget build(BuildContext context) {
    final instructor = widget.instructor;
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          RefreshIndicator(
            color: context.subtextColor,
            backgroundColor: context.cardBgColor,
            displacement: 100,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Top bar
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                            child: const Icon(Icons.arrow_back,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Yoga Instructors',
                            style: TextStyle(
                              color: themeColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Hero image
                  SizedBox(
                    width: double.infinity,
                    height: 320,
                    child: Image.network(
                      instructor['bg_image_url'] ?? instructor['image_url'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 320,
                        color: const Color(0xFF2C2C2C),
                        child: const Icon(Icons.self_improvement,
                            color: Colors.white38, size: 80),
                      ),
                    ),
                  ),

                  // Content
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 380,
                    ),
                    decoration: BoxDecoration(
                      color: context.bgColor,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: _isLoading
                        ? _buildSkeleton(context)
                        : _buildContent(context, instructor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> instructor) {
    final previewReviews = _reviews.take(2).toList();
    final bool isActive = instructor['is_active'] == true;
    final String level = instructor['level'] ?? 'All Levels';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name + phone + badges row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instructor['name'] ?? '',
                    style: const TextStyle(
                        color: themeColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    instructor['specialty'] ?? '',
                    style:
                        TextStyle(color: context.subtextColor, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Level badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _levelColor(level).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _levelColor(level).withOpacity(0.5)),
                        ),
                        child: Text(
                          level,
                          style: TextStyle(
                              color: _levelColor(level),
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Active badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isActive
                                  ? Colors.green.withOpacity(0.5)
                                  : Colors.grey.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                  color:
                                      isActive ? Colors.green : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if ((instructor['phone_number'] ?? '').toString().isNotEmpty)
              GestureDetector(
                onTap: () => _showPhoneDialog(context, instructor),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: themeColor,
                  child:
                      const Icon(Icons.phone, color: Colors.black, size: 20),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Bio
        if ((instructor['bio'] ?? '').toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              instructor['bio'],
              style: TextStyle(
                  color: context.subtextColor, fontSize: 14, height: 1.5),
            ),
          ),

        // Stats card
        Card(
          color: context.cardBgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn(context,
                    instructor['experience'] ?? '-', 'Experience'),
                _statColumn(context,
                    instructor['sessions_completed'] ?? '-', 'Sessions'),
                _statColumn(context,
                    instructor['active_clients'] ?? '-', 'Clients'),
                _statColumn(context,
                    '${instructor['sessions_per_week'] ?? '-'}/wk', 'Frequency'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Session price chip
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on_outlined,
                  color: themeColor, size: 18),
              const SizedBox(width: 8),
              Text(
                '\$${(instructor['session_price'] as num?)?.toStringAsFixed(2) ?? '0.00'} per session',
                style: const TextStyle(
                    color: themeColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Reviews header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: TextStyle(
                  color: context.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _reviews.isEmpty
                        ? (instructor['rating'] ?? '0.0').toString()
                        : (_reviews
    .map((r) => double.parse(r['rating'].toString()))
    .reduce((a, b) => a + b) /
    _reviews.length)
    .toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Overlapping avatars + read all
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_reviews.isNotEmpty)
              SizedBox(
                height: 36,
                width: (_reviews.take(4).length * 24.0) + 12,
                child: Stack(
                  children: _reviews.take(4).toList().asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    return Positioned(
                      left: i * 22.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: context.bgColor, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: themeColor,
                          backgroundImage: (r['avatar_url'] ?? '')
                                  .toString()
                                  .isNotEmpty
                              ? NetworkImage(r['avatar_url'])
                              : null,
                          child: (r['avatar_url'] ?? '').toString().isEmpty
                              ? const Icon(Icons.person,
                                  color: Colors.black, size: 14)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => YogaReviewsPage(
                      instructorId: instructor['id'],
                      instructorName: instructor['name'] ?? '',
                      rating: instructor['rating'].toString(),
                      onReviewChanged: _loadData,
                    ),
                  ),
                );
                _loadData();
              },
              child: Text(
                'Read all Reviews',
                style: TextStyle(
                    color: context.subtextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Review previews
        if (_reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No reviews yet. Be the first!',
                style:
                    TextStyle(color: context.subtextColor, fontSize: 14),
              ),
            ),
          )
        else
          ...previewReviews.map((r) => _buildReviewCard(context, r)),

        const SizedBox(height: 20),

        // Book button
        ReuseableButton(
          title: 'Book a Session',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => YogaBookingPage(
                instructor: instructor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPhoneDialog(
      BuildContext context, Map<String, dynamic> instructor) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Icon(Icons.phone, color: themeColor, size: 40),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(instructor['name'] ?? '',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(instructor['phone_number'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('OK',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return themeColor;
    }
  }

  Widget _statColumn(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: context.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style:
                TextStyle(color: context.subtextColor, fontSize: 11)),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, Map<String, dynamic> r) {
    final isMyReview = r['user_id'] == SupabaseService.currentUser?.id;
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => YogaReviewsPage(
              instructorId: widget.instructor['id'],
              instructorName: widget.instructor['name'] ?? '',
              rating: widget.instructor['rating'].toString(),
              onReviewChanged: _loadData,
            ),
          ),
        );
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(14),
          border: isMyReview
              ? Border.all(
                  color: themeColor.withOpacity(0.5), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: themeColor,
                  backgroundImage:
                      (r['avatar_url'] ?? '').toString().isNotEmpty
                          ? NetworkImage(r['avatar_url'])
                          : null,
                  child: (r['avatar_url'] ?? '').toString().isEmpty
                      ? const Icon(Icons.person,
                          color: Colors.black, size: 18)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isMyReview
                                ? 'You'
                                : (r['username'] ?? 'User'),
                            style: TextStyle(
                                color: context.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          if (isMyReview) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: themeColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Your review',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < (r['rating'] as num).toInt()
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
                      color: context.subtextColor, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              r['review_text'] ?? '',
              style: TextStyle(
                  color: context.subtextColor,
                  fontSize: 14,
                  height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _shimmer(context, width: 160, height: 24),
              const SizedBox(height: 8),
              _shimmer(context, width: 100, height: 16),
              const SizedBox(height: 8),
              _shimmer(context, width: 180, height: 28),
            ]),
            _shimmer(context, width: 44, height: 44, radius: 22),
          ],
        ),
        const SizedBox(height: 16),
        _shimmer(context, width: double.infinity, height: 60),
        const SizedBox(height: 16),
        _shimmer(context, width: double.infinity, height: 80, radius: 12),
        const SizedBox(height: 16),
        _shimmer(context, width: 180, height: 40, radius: 12),
        const SizedBox(height: 20),
        _shimmer(context, width: 100, height: 20),
        const SizedBox(height: 12),
        _shimmer(context, width: double.infinity, height: 90, radius: 14),
        const SizedBox(height: 8),
        _shimmer(context, width: double.infinity, height: 90, radius: 14),
        const SizedBox(height: 20),
        _shimmer(context, width: double.infinity, height: 50, radius: 25),
      ],
    );
  }

  Widget _shimmer(BuildContext context,
      {required double width, required double height, double radius = 8}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: _ShimmerWidget(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: context.isDark
                ? const Color(0xff3a3a3a)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(radius),
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