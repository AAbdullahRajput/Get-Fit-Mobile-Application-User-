import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/booking/appointment_booking_page.dart';
import 'package:get_fit/Presentation/pages/review/reviews_page.dart';
import 'package:get_fit/Presentation/widgets/reuseable_button.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/fitnes_trainer/trainer_booking_detail_page.dart';

Color _accent(BuildContext context) {
  return context.isDark ? themeColor : const Color(0xFF6B7A00);
}

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
  List<Map<String, dynamic>> _myBookings = [];


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // UPDATE _loadData to also fetch bookings:
Future<void> _loadData() async {
  setState(() => _isLoading = true);
  final trainerId = widget.trainer['id'] as String;
  final reviews = await SupabaseService.getTrainerReviews(trainerId);
  final myReview = await SupabaseService.getMyReview(trainerId);
  final myBookings = await SupabaseService.getMyTrainerSlotBookings();
  // filter to this trainer only
  final trainerBookings = myBookings
      .where((b) => b['trainer_id'] == trainerId)
      .toList();

  if (mounted) {
    setState(() {
      _reviews = reviews;
      _myReview = myReview;
      _myBookings = trainerBookings;
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
              // Trainer name in sheet — always on dark sheet bg, themeColor fine as-is
              Text(
                widget.trainer['name'] ?? '',
                style: const TextStyle(color: themeColor, fontSize: 14),
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
                      // Stars on dark sheet bg — themeColor fine as-is
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
          RefreshIndicator(
            color: context.subtextColor,
            backgroundColor: context.cardBgColor,
            displacement: 100,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
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
                          Text(
                            'Fitness Trainers',
                            style: TextStyle(
                              // Title on scaffold bg → accent
                              color: _accent(context),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 450,
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
    final accent = _accent(context);

    // Name + phone row (dead code block from original — preserved as-is)
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
                style: TextStyle(
                    color: accent,
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
        // Name + phone
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trainer['name'] ?? '',
                    // Trainer name on scaffold/card bg → accent
                    style: TextStyle(
                        color: accent,
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
            if (trainer['phone_number'] != null &&
                trainer['phone_number'].toString().isNotEmpty)
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      // Phone dialog always has dark bg — themeColor fine as-is
                      backgroundColor: const Color(0xFF2C2C2C),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Icon(Icons.phone, color: themeColor, size: 40),
                      content: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(trainer['name'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
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
                },
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: themeColor,
                  child: const Icon(Icons.phone, color: Colors.black, size: 20),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    // Rating badge: themeColor bg + black text — fine as-is
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _reviews.isEmpty
                            ? trainer['rating'].toString()
                            : (_reviews
                                    .map((r) => (r['rating'] as num).toDouble())
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Overlapping avatars
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
                              border: Border.all(color: context.bgColor, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              // Avatar bg: themeColor bg + black icon — fine as-is
                              backgroundColor: themeColor,
                              backgroundImage: (r['avatar_url'] ?? '').toString().isNotEmpty
                                  ? NetworkImage(r['avatar_url'])
                                  : null,
                              child: (r['avatar_url'] ?? '').toString().isEmpty
                                  ? const Icon(Icons.person, color: Colors.black, size: 14)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
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
                      child: Text(
                        'Read all Reviews',
                        style: TextStyle(
                            color: context.subtextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ],
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
                trainerExperience: trainer['experience']?.toString() ?? '',
                trainerAvatarUrl: trainer['bg_image_url'] ?? trainer['avatar_url'] ?? '',
                sessionPrice: (trainer['session_price'] as num?)?.toDouble() ?? 50.0,
                trainerRating: double.tryParse(trainer['rating']?.toString() ?? '') ?? 0.0,
              ),
            ),
          ),
        ),
        _buildMyBookingsSection(context),
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
    final trainer = widget.trainer;
    final accent = _accent(context);
    return GestureDetector(
      onTap: () async {
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
      child: Container(
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
                  // Avatar bg: themeColor bg + black icon — fine as-is
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
                            // "Your review" badge: themeColor bg + black text — fine as-is
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
                        // Stars on cardBgColor → accent
                        children: List.generate(5, (i) => Icon(
                          i < (r['rating'] as num).toInt()
                              ? Icons.star
                              : Icons.star_border,
                          color: accent,
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

  // ADD this method before _buildSkeleton:
Widget _buildMyBookingsSection(BuildContext context) {
  if (_myBookings.isEmpty) return const SizedBox.shrink();
  final accent = _accent(context);

  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 28),
    Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: themeColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.event_available, color: themeColor, size: 18),
      ),
      const SizedBox(width: 10),
      Text('My Bookings',
          style: TextStyle(
              color: context.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold)),
    ]),
    const SizedBox(height: 6),
    Text('Tap to view session details',
        style: TextStyle(color: context.subtextColor, fontSize: 13)),
    const SizedBox(height: 14),

    ..._myBookings.map((booking) {
      final date = booking['booking_date'] as String? ?? '';
      final startTime = booking['start_time'] as String? ?? '';
      final endTime = booking['end_time'] as String? ?? '';
      final price = (booking['price'] as num?)?.toDouble() ?? 0.0;
      final status = booking['status'] as String? ?? 'confirmed';

      final dt = DateTime.tryParse(date);
      final isPast = dt != null &&
          dt.isBefore(DateTime.now().subtract(const Duration(days: 1)));

      Color statusColor;
      IconData statusIcon;
      String statusLabel;

      if (status == 'cancelled') {
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusLabel = 'Cancelled';
      } else if (status == 'attended') {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = 'Attended';
      } else if (isPast) {
        statusColor = Colors.grey;
        statusIcon = Icons.lock_clock;
        statusLabel = 'Expired';
      } else {
        statusColor = accent;
        statusIcon = Icons.schedule;
        statusLabel = 'Upcoming';
      }

      // Format date
      String fmtDate = date;
      if (dt != null) {
        const months = ['Jan','Feb','Mar','Apr','May','Jun',
                        'Jul','Aug','Sep','Oct','Nov','Dec'];
        const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
        fmtDate =
            '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
      }

      // Format time
      String fmtTime(String t) {
        final parts = t.split(':');
        final h = int.parse(parts[0]);
        final m = parts[1];
        final period = h >= 12 ? 'PM' : 'AM';
        final h12 = h > 12 ? h - 12 : h == 0 ? 12 : h;
        return '$h12:$m $period';
      }

      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrainerBookingDetailPage(
              booking: booking,
              trainer: widget.trainer,
            ),
          ),
        ).then((_) => _loadData()),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withOpacity(0.4),
            ),
          ),
          child: Row(children: [
            // Date badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(statusIcon, color: statusColor, size: 22),
              ]),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(fmtDate,
                    style: TextStyle(
                        color: context.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${fmtTime(startTime)} → ${fmtTime(endTime)}',
                  style: TextStyle(
                      color: context.subtextColor, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: themeColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ]),
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      );
    }).toList(),
  ]);
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