import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/appointment_booking_page.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/reviews_page.dart';
import 'package:get_fit/Presentation/widgets/reuseable_button.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class FitnessTrainerDetailPage extends StatefulWidget {
  final Map<String, dynamic> trainer;

  const FitnessTrainerDetailPage({super.key, required this.trainer});

  @override
  State<FitnessTrainerDetailPage> createState() =>
      _FitnessTrainerDetailPageState();
}

class _FitnessTrainerDetailPageState extends State<FitnessTrainerDetailPage> {
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
    final trainerId = widget.trainer['id'] as String;
    final reviews = await SupabaseService.getTrainerReviews(trainerId);
    final myReview = await SupabaseService.getMyReview(trainerId);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _myReview = myReview;
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async => _loadData();

  void _showWriteReviewSheet() {
    double _rating = _myReview != null ? (_myReview!['rating'] as num).toDouble() : 5.0;
    final _reviewController = TextEditingController(
      text: _myReview?['review_text'] ?? '',
    );
    bool _isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _myReview != null ? 'Edit Your Review' : 'Write a Review',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.trainer['name'] ?? '',
                style: TextStyle(color: themeColor, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Star rating
              const Text('Rating', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setSheetState(() => _rating = i + 1.0),
                    child: Icon(
                      i < _rating ? Icons.star : Icons.star_border,
                      color: themeColor,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Review text
              const Text('Your Review', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _reviewController,
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
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          final text = _reviewController.text.trim();
                          if (text.isEmpty) return;
                          setSheetState(() => _isSubmitting = true);
                          try {
                            await SupabaseService.submitReview(
                              trainerId: widget.trainer['id'],
                              rating: _rating,
                              reviewText: text,
                            );
                            if (!mounted) return;
                            Navigator.pop(sheetContext);
                            _loadData();
                          } catch (e) {
                            setSheetState(() => _isSubmitting = false);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: const Text('Failed to submit review'),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          _myReview != null ? 'Update Review' : 'Submit Review',
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainer = widget.trainer;
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          // Full page scroll
          RefreshIndicator(
            color: context.subtextColor,
            backgroundColor: context.cardBgColor,
            displacement: 100,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Hero image with overlaid name
                  // Title bar
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          const Text(
                            'Fitness Trainers',
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

                  // Image below title
                  SizedBox(
                    width: double.infinity,
                    height: 320,
                    child: Image.network(
                      trainer['bg_image_url'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 320,
                        color: const Color(0xFF2C2C2C),
                        child: const Icon(Icons.person, color: Colors.white38, size: 80),
                      ),
                    ),
                  ),

                  // Content below image
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 380,
                    ),
                    decoration: BoxDecoration(
                      color: context.bgColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: _isLoading
                        ? _buildSkeleton(context)
                        : _buildContent(context, trainer),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> trainer) {
    final previewReviews = _reviews.take(2).toList();

    // Name + phone row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trainer['name'] ?? '',
                    style: const TextStyle(
                        color: themeColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trainer['training_type'] ?? '',
                    style: TextStyle(color: context.subtextColor, fontSize: 16),
                  ),
                ],
              ),
            ),
            if (trainer['phone_number'] != null && trainer['phone_number'].toString().isNotEmpty)
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF2C2C2C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Icon(Icons.phone, color: themeColor, size: 40),
                      content: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(trainer['name'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(trainer['phone_number'],
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
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                                color: themeColor, borderRadius: BorderRadius.circular(10)),
                            child: const Text('OK',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: themeColor,
                  child: const Icon(Icons.phone, color: Colors.black, size: 20),
                ),
              ),
          ],
        );
        const SizedBox(height: 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bio
        if ((trainer['bio'] ?? '').toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              trainer['bio'],
              style: TextStyle(color: context.subtextColor, fontSize: 14, height: 1.5),
            ),
          ),

        // Stats card
        Card(
          color: context.cardBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn(context, trainer['experience'] ?? '-', 'Experience'),
                _statColumn(context, trainer['training_completed'] ?? '-', 'Completed'),
                _statColumn(context, trainer['active_clients'] ?? '-', 'Active Clients'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Reviews header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Reviews',
                  style: TextStyle(
                      color: context.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trainer['rating'].toString(),
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (_reviews.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewsPage(
                            trainerId: trainer['id'],
                            trainerName: trainer['name'] ?? '',
                            rating: trainer['rating'].toString(),
                            onReviewChanged: _loadData,
                          ),
                        ),
                      );
                      _loadData();
                    },
                    child: Text('See all (${_reviews.length})',
                        style: TextStyle(color: context.subtextColor, fontSize: 12)),
                  ),
                GestureDetector(
                  onTap: () async {
                    _showWriteReviewSheet();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _myReview != null ? 'Edit Review' : '+ Review',
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Review previews
        if (_reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No reviews yet. Be the first!',
                style: TextStyle(color: context.subtextColor, fontSize: 14),
              ),
            ),
          )
        else
          ...previewReviews.map((r) => _buildReviewCard(context, r)),

        const SizedBox(height: 20),

        // Book appointment button
        ReuseableButton(
          title: 'Book an Appointment',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppointmentBookingPage(
                trainerId: trainer['id'],
                trainerName: trainer['name'] ?? '',
                trainerType: trainer['training_type'] ?? '',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statColumn(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: context.textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: context.subtextColor, fontSize: 12)),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, Map<String, dynamic> r) {
    final isMyReview = r['user_id'] == SupabaseService.currentUser?.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: isMyReview
            ? Border.all(color: themeColor.withOpacity(0.5), width: 1.5)
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
                backgroundImage: (r['avatar_url'] ?? '').toString().isNotEmpty
                    ? NetworkImage(r['avatar_url'])
                    : null,
                child: (r['avatar_url'] ?? '').toString().isEmpty
                    ? const Icon(Icons.person, color: Colors.black, size: 18)
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
                          isMyReview ? 'You' : (r['username'] ?? 'User'),
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
                      children: List.generate(5, (i) => Icon(
                        i < (r['rating'] as num).toInt()
                            ? Icons.star
                            : Icons.star_border,
                        color: themeColor,
                        size: 14,
                      )),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(r['created_at']),
                style: TextStyle(color: context.subtextColor, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            r['review_text'] ?? '',
            style: TextStyle(color: context.subtextColor, fontSize: 14, height: 1.4),
          ),
        ],
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
            ]),
            _shimmer(context, width: 36, height: 36, radius: 18),
          ],
        ),
        const SizedBox(height: 12),
        _shimmer(context, width: double.infinity, height: 50),
        const SizedBox(height: 16),
        _shimmer(context, width: double.infinity, height: 80, radius: 12),
        const SizedBox(height: 16),
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