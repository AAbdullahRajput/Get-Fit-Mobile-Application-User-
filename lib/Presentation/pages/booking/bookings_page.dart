import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/fitnes_trainer/trainer_booking_detail_page.dart';

Color _accent(BuildContext context) =>
    context.isDark ? themeColor : const Color(0xFF6B7A00);

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _trainerBookings = [];
  List<Map<String, dynamic>> _yogaBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    debugPrint('YOGA BOOKING: ${_yogaBookings.isNotEmpty ? _yogaBookings.first : "empty"}');
    final data = await SupabaseService.getAllMyBookings();
    if (mounted) {
      setState(() {
        _trainerBookings =
            List<Map<String, dynamic>>.from(data['trainer'] ?? []);
        _yogaBookings =
            List<Map<String, dynamic>>.from(data['yoga'] ?? []);
        _isLoading = false;
        if (_yogaBookings.isNotEmpty) {
          debugPrint('YOGA BOOKING: ${_yogaBookings.first}');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
            child: Row(children: [
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
              Text('My Bookings',
                  style: TextStyle(
                      color: accent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ]),
          ),

          // Tab bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: context.cardBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black,
              unselectedLabelColor: context.subtextColor,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fitness_center, size: 15),
                      const SizedBox(width: 6),
                      Text('Trainer (${_trainerBookings.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.self_improvement, size: 15),
                      const SizedBox(width: 6),
                      Text('Yoga (${_yogaBookings.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: accent))
                : RefreshIndicator(
                    color: themeColor,
                    backgroundColor: context.cardBgColor,
                    onRefresh: _load,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTrainerList(context, accent),
                        _buildYogaList(context, accent),
                      ],
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  // ── TRAINER BOOKINGS ─────────────────────────

  Widget _buildTrainerList(BuildContext context, Color accent) {
    if (_trainerBookings.isEmpty) {
      return _buildEmpty(context, Icons.fitness_center,
          'No trainer bookings yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: _trainerBookings.length,
      itemBuilder: (_, i) =>
          _buildTrainerCard(context, _trainerBookings[i], accent),
    );
  }

  Widget _buildTrainerCard(BuildContext context,
      Map<String, dynamic> booking, Color accent) {
    final trainer =
        booking['fitness_trainers'] as Map<String, dynamic>? ?? {};
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

    String fmtDate = date;
    if (dt != null) {
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      fmtDate =
          '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }

    String fmtTime(String t) {
      if (t.isEmpty) return '';
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
            trainer: trainer,
          ),
        ),
      ).then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: statusColor.withOpacity(0.35)),
        ),
        child: Column(children: [
          // Top row — trainer info
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: themeColor,
                backgroundImage:
                    (trainer['image_url'] ?? '').toString().isNotEmpty
                        ? NetworkImage(trainer['image_url'])
                        : null,
                child: (trainer['image_url'] ?? '').toString().isEmpty
                    ? const Icon(Icons.person,
                        color: Colors.black, size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(trainer['name'] ?? 'Trainer',
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  Text(trainer['training_type'] ?? '',
                      style: TextStyle(
                          color: context.subtextColor, fontSize: 12)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon, color: statusColor, size: 12),
                  const SizedBox(width: 4),
                  Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
          ),

          Divider(height: 1, color: context.isDark
              ? Colors.white10 : Colors.black12),

          // Bottom row — date, time, price
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(children: [
              _infoChip(context, accent,
                  Icons.calendar_today, fmtDate),
              const SizedBox(width: 8),
              _infoChip(context, accent, Icons.access_time,
                  '${fmtTime(startTime)} → ${fmtTime(endTime)}'),
              const Spacer(),
              Text('\$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: themeColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── YOGA BOOKINGS ─────────────────────────────

  Widget _buildYogaList(BuildContext context, Color accent) {
    if (_yogaBookings.isEmpty) {
      return _buildEmpty(
          context, Icons.self_improvement, 'No yoga bookings yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: _yogaBookings.length,
      itemBuilder: (_, i) =>
          _buildYogaCard(context, _yogaBookings[i], accent),
    );
  }

  Widget _buildYogaCard(BuildContext context,
      Map<String, dynamic> booking, Color accent) {
    final instructor =
        booking['yoga_instructors'] as Map<String, dynamic>? ?? {};
    final startDate = booking['start_date'] as String? ?? '';
    final status = booking['status'] as String? ?? 'confirmed';
    final price = (booking['total_price'] as num?)?.toDouble() ??
        (booking['price'] as num?)?.toDouble() ??
        0.0;

    final dt = DateTime.tryParse(startDate);
    final isPast = dt != null && dt.isBefore(DateTime.now());

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (status == 'cancelled') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusLabel = 'Cancelled';
    } else if (status == 'completed') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusLabel = 'Completed';
    } else if (isPast) {
      statusColor = Colors.grey;
      statusIcon = Icons.lock_clock;
      statusLabel = 'Expired';
    } else {
      statusColor = accent;
      statusIcon = Icons.schedule;
      statusLabel = 'Upcoming';
    }

    String fmtDate = startDate;
    if (dt != null) {
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      fmtDate =
          '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.35)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: themeColor,
              backgroundImage:
                  (instructor['image_url'] ?? '').toString().isNotEmpty
                      ? NetworkImage(instructor['image_url'])
                      : null,
              child:
                  (instructor['image_url'] ?? '').toString().isEmpty
                      ? const Icon(Icons.self_improvement,
                          color: Colors.black, size: 22)
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(instructor['name'] ?? 'Instructor',
                    style: TextStyle(
                        color: context.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                Text(instructor['specialty'] ?? 'Yoga',
                    style: TextStyle(
                        color: context.subtextColor, fontSize: 12)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, color: statusColor, size: 12),
                const SizedBox(width: 4),
                Text(statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
        ),

        Divider(height: 1,
            color: context.isDark ? Colors.white10 : Colors.black12),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Row(children: [
            _infoChip(
                context, accent, Icons.calendar_today, fmtDate),
            const Spacer(),
            Text('\$${price.toStringAsFixed(2)}',
                style: TextStyle(
                    color: themeColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────

  Widget _infoChip(BuildContext context, Color accent,
      IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: accent, size: 12),
      const SizedBox(width: 4),
      Text(label,
          style:
              TextStyle(color: context.subtextColor, fontSize: 11)),
    ]);
  }

  Widget _buildEmpty(
      BuildContext context, IconData icon, String label) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: context.subtextColor, size: 52),
        const SizedBox(height: 12),
        Text(label,
            style: TextStyle(
                color: context.subtextColor, fontSize: 14)),
      ]),
    );
  }
}1