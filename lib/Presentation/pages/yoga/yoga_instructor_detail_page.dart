import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_reviews_page.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_booking_page.dart';
import 'package:get_fit/Presentation/widgets/reuseable_button.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/yoga/instructor_class_detail_page.dart';
import 'package:get_fit/Presentation/pages/yoga/session_detail_page.dart';

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
List<Map<String, dynamic>> _allSessions = [];
List<Map<String, dynamic>> _classes = [];          
List<Map<String, dynamic>> _bookedSessions = [];
bool _hasActiveBooking = false;
Set<String> _feedClassIds = {};
int? _bookedSessionCount;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // REPLACE the entire _loadData method:
Future<void> _loadData() async {
  setState(() => _isLoading = true);
  final instructorId = widget.instructor['id'] as String;

  final reviews     = await SupabaseService.getYogaInstructorReviews(instructorId);
  final myReview    = await SupabaseService.getMyYogaReview(instructorId);
  final hasBooking  = await SupabaseService.hasActiveBookingWithInstructor(instructorId);
  final feedClasses = await SupabaseService.getUserFeedClasses();

  List<Map<String, dynamic>> bookedSessions = [];
  int? bookedSessionCount;

  if (hasBooking) {
    bookedSessions     = await SupabaseService.getUserBookedSessions(instructorId);
    bookedSessionCount = bookedSessions.length;
  }

  // fetch ALL instructor sessions (for showing locked cards to unbooked users)
  final allSessions = await SupabaseService.getInstructorSessions(instructorId);

  // fetch instructor's offered classes (shown locked until a session is booked)
  final classes = await SupabaseService.getInstructorPaidClasses(instructorId);


  if (mounted) {
    setState(() {
      _reviews            = reviews;
      _myReview           = myReview;
      _allSessions        = allSessions;
      _classes            = classes;                 
      _bookedSessions     = bookedSessions;
      _hasActiveBooking   = hasBooking;
      _bookedSessionCount = bookedSessionCount;
      _feedClassIds       = feedClasses.map((f) => f['class_id'] as String).toSet();
      _isLoading          = false;
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
                      instructor['bg_image_url'] ??
                          instructor['image_url'] ??
                          '',
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

  Widget _buildContent(
      BuildContext context, Map<String, dynamic> instructor) {
    final previewReviews = _reviews.take(2).toList();
    final bool isActive = instructor['is_active'] == true;
    final String level = instructor['level'] ?? 'All Levels';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name + phone + badges
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
                    style: TextStyle(
                        color: context.subtextColor, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
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
                                color: isActive
                                    ? Colors.green
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                  color: isActive
                                      ? Colors.green
                                      : Colors.grey,
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
                  child: const Icon(Icons.phone,
                      color: Colors.black, size: 20),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
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
                _statColumn(
                    context,
                    '${instructor['sessions_per_week'] ?? '-'}/wk',
                    'Frequency'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Session price
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
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _reviews.isEmpty
                    ? double.parse(instructor['rating'].toString())
                        .toStringAsFixed(1)
                    : (_reviews
                                .map((r) =>
                                    double.parse(r['rating'].toString()))
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
                  children: _reviews
                      .take(4)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    return Positioned(
                      left: i * 22.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: context.bgColor, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: themeColor,
                          backgroundImage: (r['avatar_url'] ?? '')
                                  .toString()
                                  .isNotEmpty
                              ? NetworkImage(r['avatar_url'])
                              : null,
                          child:
                              (r['avatar_url'] ?? '').toString().isEmpty
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

        // Review previews or placeholder
        if (_reviews.isEmpty)
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
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: context.cardBgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: themeColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.rate_review_outlined,
                      color: themeColor, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'No reviews yet. Be the first!',
                    style: TextStyle(
                        color: context.subtextColor, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to write a review',
                    style: TextStyle(
                        color: themeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ],
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
      builder: (_) => YogaBookingPage(instructor: instructor),
    ),
  ).then((_) => _loadData()),
),
const SizedBox(height: 24),
_buildClassesSection(context),

_buildBookedSessionsSection(context),

const SizedBox(height: 24),
      ],
    );
  }

Widget _buildBookedSessionsSection(BuildContext context) {
  if (_allSessions.isEmpty) return const SizedBox.shrink();

  final bookedIds = _bookedSessions
      .map((b) => b['session_id'] as String? ?? '')
      .toSet();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 28),
      Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.event_note, color: themeColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text('Sessions',
            style: TextStyle(
                color: context.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const Spacer(),
        if (!_hasActiveBooking)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: const Text('Book to unlock',
                style: TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
      ]),
      const SizedBox(height: 6),
      Text(
        _hasActiveBooking
            ? 'You have $_bookedSessionCount active session${_bookedSessionCount == 1 ? '' : 's'}'
            : 'Book a session to unlock classes',
        style: TextStyle(color: context.subtextColor, fontSize: 13),
      ),
      const SizedBox(height: 14),

      ..._allSessions.map((session) {
        final sessionId = session['id'] as String;
        final isBooked  = bookedIds.contains(sessionId);
        final isExpired = _isSessionExpired(session['session_end'] as String? ?? '');
        final booking   = _bookedSessions.firstWhere(
          (b) => b['session_id'] == sessionId,
          orElse: () => {},
        );

        return GestureDetector(
          onTap: isBooked && !isExpired
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionDetailPage(
                        booking: booking,
                        instructor: widget.instructor,
                      ),
                    ),
                  ).then((_) => _loadData())
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: context.cardBgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isBooked && !isExpired
                    ? themeColor.withOpacity(0.4)
                    : Colors.white12,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Top color band
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isExpired
                      ? Colors.grey
                      : isBooked
                          ? themeColor
                          : Colors.white12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  // Date badge
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isBooked && !isExpired
                          ? themeColor
                          : context.isDark
                              ? Colors.white12
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(
                        _dayName(session['session_start'] as String),
                        style: TextStyle(
                          color: isBooked && !isExpired ? Colors.black : context.subtextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateTime.parse(session['session_start'] as String).day.toString(),
                        style: TextStyle(
                          color: isBooked && !isExpired ? Colors.black : context.textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(session['title'] as String? ?? '',
                          style: TextStyle(
                              color: context.textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(session['session_start'] as String)}  →  ${_formatDate(session['session_end'] as String)}',
                        style: TextStyle(color: context.subtextColor, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.class_outlined, size: 12, color: context.subtextColor),
                        const SizedBox(width: 4),
                        Text('${session['total_classes']} classes',
                            style: TextStyle(color: context.subtextColor, fontSize: 11)),
                      ]),
                    ]),
                  ),

                  // Status
                  if (isExpired)
                    _statusChip('Expired', Colors.grey)
                  else if (isBooked)
                    _statusChip('Booked', themeColor)
                  else
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_outline,
                          color: Colors.white54, size: 18),
                    ),
                ]),
              ),

              // Lock overlay hint for unbooked
              if (!isBooked)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(18)),
                  ),
                  child: const Center(
                    child: Text('Book a session to unlock',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                ),

              // Booked → tap hint
              if (isBooked && !isExpired)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(18)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.touch_app, color: themeColor, size: 14),
                    const SizedBox(width: 6),
                    Text('Tap to view classes & time slots',
                        style: TextStyle(
                            color: themeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
            ]),
          ),
        );
      }).toList(),
    ],
  );
}

Widget _statusChip(String label, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  decoration: BoxDecoration(
    color: color.withOpacity(0.15),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: color.withOpacity(0.4)),
  ),
  child: Text(label,
      style: TextStyle(
          color: color, fontSize: 11, fontWeight: FontWeight.bold)),
);

String _dayName(String dateStr) {
  final dt = DateTime.parse(dateStr);
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[dt.weekday - 1];
}

bool _isSessionExpired(String endDate) {
  if (endDate.isEmpty) return false;
  final end = DateTime.tryParse(endDate);
  if (end == null) return false;
  return DateTime.now().isAfter(end.add(const Duration(days: 1)));
}


Widget _buildClassesSection(BuildContext context) {
  if (_classes.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.self_improvement, color: themeColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text('Classes',
            style: TextStyle(
                color: context.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const Spacer(),
        if (!_hasActiveBooking)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: const Text('Book to unlock',
                style: TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
      ]),
      const SizedBox(height: 14),
      ..._classes.map((cls) => _buildPaidClassCard(context, cls)),
    ],
  );
}
  // ── Paid class card ──
  Widget _buildPaidClassCard(
      BuildContext context, Map<String, dynamic> cls) {
    final classId = cls['id'] as String;
    final isUnlocked = _hasActiveBooking;
    final isInFeed = _feedClassIds.contains(classId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: isUnlocked
            ? Border.all(color: themeColor.withOpacity(0.25))
            : Border.all(color: Colors.white12),
      ),
      child: GestureDetector(
  onTap: isUnlocked
      ? () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InstructorClassDetailPage(
                classData: cls,
                instructorData: widget.instructor,
              ),
            ),
          )
      : () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => YogaBookingPage(instructor: widget.instructor),
            ),
          ).then((_) => _loadData()),
  child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with lock overlay
            Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: (cls['image_url'] ?? '').isNotEmpty
                    ? Image.network(
                        cls['image_url'],
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 140,
                          color: context.isDark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          child: Icon(Icons.play_circle_outline,
                              color: context.subtextColor, size: 48),
                        ),
                      )
                    : Container(
                        height: 140,
                        color: context.isDark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        child: Icon(Icons.play_circle_outline,
                            color: context.subtextColor, size: 48),
                      ),
              ),

              // Lock overlay for unbooked users
              if (!isUnlocked)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: Container(
                      color: Colors.black.withOpacity(0.65),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white30, width: 1.5),
                            ),
                            child: const Icon(Icons.lock_outline,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Book a session to unlock',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Duration badge — bottom left
              Positioned(
                bottom: 8,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${cls['duration_minutes']} min',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              // Level badge — top left
              Positioned(
                top: 8,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cls['level'] ?? '',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          // Info + Add to Feed button
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cls['title'] ?? '',
                        style: TextStyle(
                            color: isUnlocked
                                ? context.textColor
                                : context.subtextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? Colors.white10
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cls['class_type'] ?? 'guide',
                        style: TextStyle(
                            color: context.subtextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if ((cls['description'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    cls['description'],
                    style: TextStyle(
                        color: context.subtextColor,
                        fontSize: 13,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),

                // Add / Remove / Book to Unlock button
                SizedBox(
                  width: double.infinity,
                  child: isUnlocked
                      ? ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              if (isInFeed) {
                                await SupabaseService
                                    .removeClassFromFeed(classId);
                                setState(() =>
                                    _feedClassIds.remove(classId));
                              } else {
                                await SupabaseService.addClassToFeed(
                                  classId: classId,
                                  instructorId: widget.instructor['id']
                                      as String,
                                );
                                setState(
                                    () => _feedClassIds.add(classId));
                              }
                            } catch (_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Something went wrong. Try again.')),
                                );
                              }
                            }
                          },
                          icon: Icon(
                              isInFeed
                                  ? Icons.remove_circle_outline
                                  : Icons.add_circle_outline,
                              size: 18),
                          label: Text(isInFeed
                              ? 'Remove from Feed'
                              : 'Add to Feed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInFeed
                                ? Colors.red.withOpacity(0.15)
                                : themeColor,
                            foregroundColor: isInFeed
                                ? Colors.redAccent
                                : Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => YogaBookingPage(
                                  instructor: widget.instructor),
                            ),
                          ),
                          icon: const Icon(Icons.lock_outline,
                              size: 16, color: Colors.orange),
                          label: const Text('Book to Unlock',
                              style:
                                  TextStyle(color: Colors.orange)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Colors.orange, width: 1),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhoneDialog(
      BuildContext context, Map<String, dynamic> instructor) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Icon(Icons.phone, color: themeColor, size: 40),
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

  Widget _statColumn(
      BuildContext context, String value, String label) {
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

  Widget _buildReviewCard(
      BuildContext context, Map<String, dynamic> r) {
    final isMyReview =
        r['user_id'] == SupabaseService.currentUser?.id;
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
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: const Text('Your review',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i <
                                    double.parse(
                                            r['rating'].toString())
                                        .round()
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
  if (iso == null || iso.isEmpty) return '';
  try {
    final dt = DateTime.parse(iso);
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
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
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
        const SizedBox(height: 28),
        _shimmer(context, width: 200, height: 22),
        const SizedBox(height: 14),
        _shimmer(context, width: double.infinity, height: 220, radius: 16),
        const SizedBox(height: 14),
        _shimmer(context, width: double.infinity, height: 220, radius: 16),
      ],
    );
  }

  Widget _shimmer(BuildContext context,
      {required double width,
      required double height,
      double radius = 8}) {
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