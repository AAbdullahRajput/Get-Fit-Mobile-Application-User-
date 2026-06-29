import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/fitnes_trainer/trainer_content_page.dart';

Color _accent(BuildContext context) =>
    context.isDark ? themeColor : const Color(0xFF6B7A00);

class TrainerBookingDetailPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> trainer;

  const TrainerBookingDetailPage({
    super.key,
    required this.booking,
    required this.trainer,
  });

  @override
  State<TrainerBookingDetailPage> createState() =>
      _TrainerBookingDetailPageState();
}

class _TrainerBookingDetailPageState
    extends State<TrainerBookingDetailPage> {
  Map<String, dynamic>? _attendance;
  bool _isLoading = true;
  Timer? _ticker;

  String get _bookingId => widget.booking['id'] as String;
  String get _bookingDate =>
      widget.booking['booking_date'] as String;
  String get _startTime => widget.booking['start_time'] as String;
  String get _endTime => widget.booking['end_time'] as String;
  String get _weeklySlotId =>
      widget.booking['weekly_slot_id'] as String;
  String get _trainerId => widget.booking['trainer_id'] as String;
  String get _status =>
      widget.booking['status'] as String? ?? 'confirmed';

  bool get isDone => _attendance?['status'] == 'done';

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final attendance =
        await SupabaseService.getTrainerSlotAttendance(_bookingId);
    if (mounted) {
      setState(() {
        _attendance = attendance;
        _isLoading = false;
      });
    }
  }

  // ── Time helpers ──────────────────────────────

  DateTime _slotStart() {
    final parts = _startTime.split(':');
    final d = DateTime.parse(_bookingDate);
    return DateTime(d.year, d.month, d.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }

  DateTime _slotEnd() {
    final parts = _endTime.split(':');
    final d = DateTime.parse(_bookingDate);
    return DateTime(d.year, d.month, d.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }

  bool get _isLive {
    final now = DateTime.now();
    return now.isAfter(_slotStart()) && now.isBefore(_slotEnd());
  }

  bool get _isExpired => DateTime.now().isAfter(_slotEnd());
  bool get _isUpcoming => DateTime.now().isBefore(_slotStart());

  Duration get _timeUntilStart {
    final diff = _slotStart().difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Duration get _timeRemaining {
    final diff = _slotEnd().difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String _fmtDuration(Duration d) {
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m';
    }
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s';
    }
    return '${d.inMinutes % 60}m ${d.inSeconds % 60}s';
  }

  String _fmtTime(String t) {
    final parts = t.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : h == 0 ? 12 : h;
    return '$h12:$m $period';
  }

  String _fmtDate(String dateStr) {
    final dt = DateTime.parse(dateStr);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // ── Actions ───────────────────────────────────

  Future<void> _toggleDone() async {
    try {
      await SupabaseService.markTrainerSlotAttendance(
        bookingId: _bookingId,
        trainerId: _trainerId,
        weeklySlotId: _weeklySlotId,
        bookingDate: _bookingDate,
        isDone: !isDone,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to update. Try again.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<void> _cancelBooking() async {
    final price =
        (widget.booking['price'] as num?)?.toDouble() ?? 0.0;
    final last4 =
        widget.booking['payment_card_last4'] as String? ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Column(children: [
          Icon(Icons.cancel_outlined,
              color: Colors.redAccent, size: 48),
          SizedBox(height: 12),
          Text('Cancel Booking',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'Are you sure you want to cancel this session?',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.replay_circle_filled,
                  color: Colors.green, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '\$${price.toStringAsFixed(2)} will be refunded to your card${last4.isNotEmpty ? ' ending in ••••$last4' : ''} within 5–7 business days.',
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      height: 1.4),
                ),
              ),
            ]),
          ),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep It',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Yes, Cancel',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupabaseService.cancelTrainerSlotBooking(_bookingId);
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Column(children: [
              Icon(Icons.check_circle,
                  color: Colors.green, size: 48),
              SizedBox(height: 12),
              Text('Booking Cancelled',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ]),
            content: Text(
              'Your booking has been cancelled. \$${price.toStringAsFixed(2)} will be refunded to your card${last4.isNotEmpty ? ' ending in ••••$last4' : ''} within 5–7 business days.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('OK',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to cancel. Try again.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  // ── Build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    final isCancelled = _status == 'cancelled';

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
                child: const Icon(Icons.arrow_back,
                    color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.trainer['name'] ?? 'Session Detail',
                  style: TextStyle(
                      color: themeColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Cancel button (only if upcoming and not cancelled)
              if (_isUpcoming && !isCancelled)
                TextButton.icon(
                  onPressed: _cancelBooking,
                  icon: const Icon(Icons.cancel_outlined,
                      color: Colors.redAccent, size: 18),
                  label: const Text('Cancel',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold)),
                ),
            ]),
          ),

          Expanded(
            child: _isLoading
                ? Center(
                    child:
                        CircularProgressIndicator(color: accent))
                : RefreshIndicator(
                    color: themeColor,
                    backgroundColor: context.cardBgColor,
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _buildStatusBanner(
                              context, accent, isCancelled),
                          const SizedBox(height: 20),
                          _buildInfoCard(context, accent),
                          const SizedBox(height: 20),
                          if (!isCancelled)
                            _buildTimingBlock(
                                context, accent),
                          const SizedBox(height: 20),
                          _buildTrainerCard(context, accent),
                        ],
                      ),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, Color accent,
      bool isCancelled) {
    Color color;
    IconData icon;
    String label;

    if (isCancelled) {
      color = Colors.red;
      icon = Icons.cancel;
      label = 'Cancelled';
    } else if (isDone) {
      color = Colors.green;
      icon = Icons.check_circle;
      label = 'Completed';
    } else if (_isExpired) {
      color = Colors.grey;
      icon = Icons.lock_clock;
      label = 'Expired';
    } else if (_isLive) {
      color = Colors.green;
      icon = Icons.radio_button_checked;
      label = 'Live Now';
    } else {
      color = accent;
      icon = Icons.schedule;
      label = 'Upcoming';
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        const Spacer(),
        if (_isLive && !isDone)
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 2)
              ],
            ),
          ),
      ]),
    );
  }

  Widget _buildInfoCard(BuildContext context, Color accent) {
    final price =
        (widget.booking['price'] as num?)?.toDouble() ?? 0.0;
    final last4 =
        widget.booking['payment_card_last4'] as String? ?? '';
    final notes = widget.booking['notes'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text('Session Details',
            style: TextStyle(
                color: context.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _infoRow(context, accent, Icons.calendar_today_rounded,
            'Date', _fmtDate(_bookingDate)),
        const SizedBox(height: 12),
        _infoRow(context, accent, Icons.access_time_rounded,
            'Time',
            '${_fmtTime(_startTime)} → ${_fmtTime(_endTime)}'),
        const SizedBox(height: 12),
        _infoRow(
            context,
            accent,
            Icons.timer_outlined,
            'Duration',
            '${widget.booking['trainer_weekly_slots']?['duration_minutes'] ?? 60} min'),
        const SizedBox(height: 12),
        _infoRow(
            context,
            accent,
            Icons.attach_money,
            'Paid',
            '\$${price.toStringAsFixed(2)}${last4.isNotEmpty ? '  •  ••••$last4' : ''}'),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _infoRow(context, accent, Icons.note_outlined,
              'Notes', notes),
        ],
      ]),
    );
  }

  Widget _buildTimingBlock(BuildContext context, Color accent) {
    // ── EXPIRED ──
    if (_isExpired) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(children: [
          const Icon(Icons.lock_clock,
              color: Colors.grey, size: 36),
          const SizedBox(height: 10),
          const Text('Session Ended',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            isDone
                ? 'You marked this session as done.'
                : 'You did not mark this session as done.',
            style: TextStyle(
                color: context.subtextColor, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ]),
      );
    }

    // ── LIVE ──
    if (_isLive) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: Colors.green.withOpacity(0.4)),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2)
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text('Session is Live!',
                style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(
            'Ends in  ${_fmtDuration(_timeRemaining)}',
            style: const TextStyle(
                color: Colors.green, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // JOIN SESSION — locked if already marked done
          if (isDone)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const Icon(Icons.lock,
                    color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Session Joined & Completed',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ]),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrainerContentPage(
                      trainer: widget.trainer,
                      activeBooking: widget.booking,
                    ),
                  ),
                ).then((_) => _load()),
                icon: const Icon(Icons.play_circle_fill,
                    color: Colors.black, size: 20),
                label: const Text('Join Session',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

          const SizedBox(height: 10),

          // Mark Attendance (always visible when live)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _toggleDone,
              icon: Icon(
                  isDone
                      ? Icons.remove_circle_outline
                      : Icons.check_circle_outline,
                  size: 16,
                  color:
                      isDone ? Colors.orange : Colors.green),
              label: Text(
                  isDone
                      ? 'Unmark Attendance'
                      : 'Mark Attendance',
                  style: TextStyle(
                      color: isDone
                          ? Colors.orange
                          : Colors.green,
                      fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: isDone
                        ? Colors.orange.withOpacity(0.5)
                        : Colors.green.withOpacity(0.5)),
                padding:
                    const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Completion note when done
          if (isDone) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You\'ve marked attendance. Join Session is locked until you unmark.',
                    style: TextStyle(
                        color: Colors.green.shade300,
                        fontSize: 11,
                        height: 1.4),
                  ),
                ),
              ]),
            ),
          ],
        ]),
      );
    }

    // ── UPCOMING — show countdown ──
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Column(children: [
        Icon(Icons.schedule, color: accent, size: 36),
        const SizedBox(height: 10),
        Text('Starts in',
            style: TextStyle(
                color: context.subtextColor, fontSize: 13)),
        const SizedBox(height: 6),
        Text(
          _fmtDuration(_timeUntilStart),
          style: TextStyle(
              color: accent,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1),
        ),
        const SizedBox(height: 6),
        Text(
          '${_fmtDate(_bookingDate)}  •  ${_fmtTime(_startTime)} → ${_fmtTime(_endTime)}',
          style: TextStyle(
              color: context.subtextColor, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  Widget _buildTrainerCard(BuildContext context, Color accent) {
    final trainer = widget.trainer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: themeColor,
          backgroundImage:
              (trainer['image_url'] ?? '').toString().isNotEmpty
                  ? NetworkImage(trainer['image_url'])
                  : null,
          child:
              (trainer['image_url'] ?? '').toString().isEmpty
                  ? const Icon(Icons.person,
                      color: Colors.black, size: 28)
                  : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(trainer['name'] ?? '',
                style: TextStyle(
                    color: context.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text(trainer['training_type'] ?? '',
                style: TextStyle(
                    color: context.subtextColor, fontSize: 13)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.star, color: themeColor, size: 14),
              const SizedBox(width: 4),
              Text(
                trainer['rating']?.toString() ?? '',
                style: TextStyle(
                    color: context.subtextColor, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Icon(Icons.work_outline, color: accent, size: 13),
              const SizedBox(width: 4),
              Text(
                '${trainer['experience'] ?? 'N/A'} exp',
                style: TextStyle(
                    color: context.subtextColor, fontSize: 12),
              ),
            ]),
          ]),
        ),
        if ((trainer['phone_number'] ?? '').toString().isNotEmpty)
          CircleAvatar(
            radius: 20,
            backgroundColor: themeColor,
            child: const Icon(Icons.phone,
                color: Colors.black, size: 18),
          ),
      ]),
    );
  }

  Widget _infoRow(BuildContext context, Color accent,
      IconData icon, String label, String value) {
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: accent, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(label,
              style: TextStyle(
                  color: context.subtextColor, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: context.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    ]);
  }
}